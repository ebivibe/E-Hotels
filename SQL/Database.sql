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
    hc.chain_id = h.chain_id; INSERT INTO HotelChain(chain_name, email, street_number, street_name, city, province, country, zip) VALUES ('Hotels 1', 'hotel1@hotels.com', 68, 'First Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 1, 'hotel1@hotels1.com', 181, 'Third Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (23, 1, 41.67, 1, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (36, 1, 43.33, 2, true, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (60, 1, 43.33, 3, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (47, 1, 34.17, 4, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (72, 1, 39.17, 5, true, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (1, 'Ryan Price', 1, 352, 'Bank Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (1, 1);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (2, 'Sarah Young', 1, 193, 'Bank Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (3, 'Ashley Miller', 1, 55, 'Metcalfe Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (4, 'Meg Ward', 1, 239, 'Oak Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (5, 'Mary Jones', 1, 217, 'Metcalfe Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (6, 'Jon Johnson', 249, 'Pine Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '102 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '109 DAY', false, 4, 6);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '173 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '180 DAY', false, 2, 6);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '91 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '96 DAY', false, 4, 6);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (7, 'Natalia Wilson', 208, 'Third Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '29 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '33 DAY', false, 4, 7);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '196 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '198 DAY', false, 1, 7);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '92 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '99 DAY', false, 5, 7);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (8, 'Sahil Johnson', 330, 'Laurier Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '101 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '102 DAY', false, 1, 8);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '99 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '103 DAY', false, 5, 8);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '170 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '171 DAY', false, 4, 8);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 2, 'hotel2@hotels1.com', 153, 'Bay Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (68, 2, 83.33, 1, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (11, 2, 76.67, 2, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (70, 2, 96.67, 3, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (94, 2, 98.33, 4, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (87, 2, 96.67, 5, false, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (9, 'Sarah Jones', 2, 242, 'Main Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (9, 2);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (10, 'Natalia Brown', 2, 176, 'Third Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (11, 'Mary Brown', 2, 49, 'Oak Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (12, 'Sahil Perez', 2, 169, 'Metcalfe Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (13, 'Mary Wood', 2, 245, 'Second Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (14, 'Alex Williams', 144, 'Elm Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '114 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '118 DAY', false, 10, 14);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '84 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '85 DAY', false, 8, 14);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '111 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '114 DAY', false, 7, 14);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (15, 'Ryan Price', 191, 'Third Crescent', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '118 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '122 DAY', false, 6, 15);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '98 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '101 DAY', false, 6, 15);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '173 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '175 DAY', false, 9, 15);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (16, 'Paul Sanchez', 396, 'Pine Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '122 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '129 DAY', false, 10, 16);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '58 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '61 DAY', false, 10, 16);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '99 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '101 DAY', false, 9, 16);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 3, 'hotel3@hotels1.com', 166, 'Laurier Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (24, 3, 110.00, 1, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (6, 3, 150.00, 2, false, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (43, 3, 127.50, 3, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (17, 3, 150.00, 4, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (64, 3, 117.50, 5, false, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (17, 'Elizabeth Davis', 3, 41, 'Second Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (17, 3);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (18, 'Hudi Williams', 3, 378, 'Main Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (19, 'Mary Price', 3, 9, 'Second Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (20, 'Natalia Miller', 3, 106, 'Oak Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (21, 'Sarah Miller', 3, 264, 'First Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (22, 'Liam Williams', 123, 'Laurier Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '16 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '17 DAY', false, 3, 22);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '111 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '115 DAY', false, 6, 22);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '100 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '103 DAY', false, 11, 22);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (23, 'Ryan Miller', 75, 'Laurier Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '62 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '68 DAY', false, 12, 23);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '97 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '99 DAY', false, 13, 23);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '61 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '68 DAY', false, 5, 23);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (24, 'Sarah Cook', 80, 'Main Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '75 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '82 DAY', false, 7, 24);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '159 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '160 DAY', false, 8, 24);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '168 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '172 DAY', false, 8, 24);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 4, 'hotel4@hotels1.com', 162, 'Bank Crescent', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (50, 4, 200.00, 1, false, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (10, 4, 186.67, 2, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (34, 4, 136.67, 3, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (34, 4, 133.33, 4, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (33, 4, 153.33, 5, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (25, 'Alex Wood', 4, 110, 'Metcalfe Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (25, 4);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (26, 'Natalia Sanchez', 4, 181, 'Willow Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (27, 'Jon Williams', 4, 226, 'Willow Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (28, 'Bob Perez', 4, 256, 'First Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (29, 'Alex Smith', 4, 313, 'Second Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (30, 'David Young', 89, 'Metcalfe Crescent', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '47 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '50 DAY', false, 3, 30);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '128 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '130 DAY', false, 19, 30);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '60 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '61 DAY', false, 5, 30);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (31, 'Bob Wilson', 380, 'Laurier Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '42 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '45 DAY', false, 15, 31);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '187 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '189 DAY', false, 12, 31);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '130 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '135 DAY', false, 10, 31);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (32, 'Hudi Smith', 30, 'Elm Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '43 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '47 DAY', false, 4, 32);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '18 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '20 DAY', false, 19, 32);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '22 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '28 DAY', false, 8, 32);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 5, 'hotel5@hotels1.com', 39, 'Bank Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (57, 5, 208.33, 1, true, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (23, 5, 170.83, 2, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (48, 5, 166.67, 3, false, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (40, 5, 166.67, 4, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (4, 5, 229.17, 5, true, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (33, 'Jon Johnson', 5, 375, 'Main Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (33, 5);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (34, 'Meg Rogers', 5, 376, 'Second Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (35, 'Sahil Young', 5, 345, 'Third Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (36, 'Emily Brown', 5, 383, 'Oak Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (37, 'Nick Cook', 5, 176, 'Oak Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (38, 'Nick Davis', 328, 'Pine Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '20 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '24 DAY', false, 17, 38);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '153 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '159 DAY', false, 12, 38);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '117 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '122 DAY', false, 15, 38);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (39, 'Liam Rogers', 309, 'Bay Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '45 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '51 DAY', false, 7, 39);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '6 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '10 DAY', false, 14, 39);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '150 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '157 DAY', false, 23, 39);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (40, 'Mary Smith', 115, 'Third Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '182 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '185 DAY', false, 12, 40);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '78 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '85 DAY', false, 10, 40);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '189 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '193 DAY', false, 12, 40);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 1, 'hotel6@hotels1.com', 147, 'Elm Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (1, 6, 42.50, 1, true, true, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (77, 6, 45.00, 2, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (57, 6, 43.33, 3, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (32, 6, 40.00, 4, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (94, 6, 36.67, 5, false, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (41, 'Andrew Williams', 6, 347, 'Second Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (41, 6);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (42, 'Sarah Perez', 6, 392, 'Laurier Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (43, 'Andrew Young', 6, 220, 'Third Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (44, 'Ryan Hernandez', 6, 309, 'First Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (45, 'Sarah Miller', 6, 400, 'Willow Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (46, 'Nick Hernandez', 98, 'Third Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '40 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '45 DAY', false, 25, 46);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '76 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '81 DAY', false, 28, 46);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '130 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '133 DAY', false, 9, 46);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (47, 'Ashley Perez', 377, 'Main Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '15 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '16 DAY', false, 5, 47);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '152 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '155 DAY', false, 25, 47);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '167 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '172 DAY', false, 14, 47);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (48, 'Andrew Davis', 178, 'Main Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '154 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '156 DAY', false, 8, 48);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '129 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '135 DAY', false, 12, 48);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '117 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '123 DAY', false, 8, 48);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 2, 'hotel7@hotels1.com', 292, 'Laurier Street', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (73, 7, 93.33, 1, true, true, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (67, 7, 66.67, 2, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (17, 7, 75.00, 3, true, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (93, 7, 86.67, 4, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (46, 7, 70.00, 5, false, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (49, 'Sahil Hernandez', 7, 39, 'Laurier Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (49, 7);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (50, 'Bob Wood', 7, 22, 'Oak Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (51, 'Jon Wilson', 7, 267, 'First Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (52, 'Meg Wood', 7, 27, 'Metcalfe Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (53, 'Nick Price', 7, 65, 'Metcalfe Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (54, 'Hudi Ward', 339, 'Willow Crescent', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '204 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '208 DAY', false, 21, 54);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '148 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '150 DAY', false, 30, 54);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '144 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '147 DAY', false, 2, 54);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (55, 'Paul Price', 84, 'Main Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '185 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '189 DAY', false, 28, 55);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '179 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '182 DAY', false, 19, 55);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '161 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '164 DAY', false, 23, 55);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (56, 'Hudi Wilson', 302, 'Bay Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '55 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '56 DAY', false, 7, 56);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '59 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '64 DAY', false, 33, 56);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '91 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '92 DAY', false, 24, 56);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 3, 'hotel8@hotels1.com', 213, 'Oak Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (83, 8, 115.00, 1, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (69, 8, 130.00, 2, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (89, 8, 115.00, 3, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (50, 8, 135.00, 4, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (55, 8, 122.50, 5, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (57, 'Mary Miller', 8, 267, 'Third Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (57, 8);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (58, 'Natalia Stewart', 8, 144, 'Second Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (59, 'Andrew Perez', 8, 365, 'Metcalfe Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (60, 'Jon Cook', 8, 276, 'Bank Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (61, 'David Sanchez', 8, 155, 'Bay Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (62, 'Emily Young', 113, 'First Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '86 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '90 DAY', false, 34, 62);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '45 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '51 DAY', false, 38, 62);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '15 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '16 DAY', false, 3, 62);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (63, 'Ivana Wood', 150, 'Laurier Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '161 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '162 DAY', false, 34, 63);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '156 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '163 DAY', false, 25, 63);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '29 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '34 DAY', false, 17, 63);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (64, 'Paul Miller', 372, 'Third Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '26 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '27 DAY', false, 20, 64);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '171 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '176 DAY', false, 39, 64);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '206 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '209 DAY', false, 18, 64);
INSERT INTO HotelChain(chain_name, email, street_number, street_name, city, province, country, zip) VALUES ('Hotels 2', 'hotel2@hotels.com', 252, 'Willow Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 1, 'hotel1@hotels2.com', 138, 'First Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (69, 9, 38.33, 1, false, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (12, 9, 45.00, 2, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (45, 9, 37.50, 3, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (27, 9, 34.17, 4, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (72, 9, 45.00, 5, true, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (65, 'Bob Miller', 9, 90, 'Second Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (65, 9);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (66, 'Ivana Brown', 9, 115, 'Main Boulevard', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (67, 'Natalia Stewart', 9, 236, 'Second Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (68, 'Elizabeth Stewart', 9, 96, 'Elm Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (69, 'Paul Young', 9, 10, 'Bay Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (70, 'Liam Perez', 313, 'Pine Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '15 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '20 DAY', false, 33, 70);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '194 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '201 DAY', false, 14, 70);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '6 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '9 DAY', false, 12, 70);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (71, 'Susan Hernandez', 95, 'Second Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '127 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '134 DAY', false, 33, 71);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '58 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '61 DAY', false, 32, 71);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '46 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '48 DAY', false, 21, 71);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (72, 'Liam Wilson', 77, 'Pine Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '199 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '203 DAY', false, 10, 72);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '38 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '40 DAY', false, 8, 72);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '62 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '68 DAY', false, 21, 72);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 2, 'hotel2@hotels2.com', 74, 'Elm Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (89, 10, 83.33, 1, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (5, 10, 96.67, 2, true, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (78, 10, 91.67, 3, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (32, 10, 96.67, 4, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (12, 10, 71.67, 5, false, true, true, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (73, 'Paul Brown', 10, 93, 'Laurier Boulevard', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (73, 10);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (74, 'Natalia Ward', 10, 212, 'Bay Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (75, 'Hudi Johnson', 10, 134, 'Third Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (76, 'Mary Stewart', 10, 142, 'Bay Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (77, 'David Ward', 10, 337, 'First Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (78, 'Nick Cook', 81, 'Bank Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '94 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '99 DAY', false, 22, 78);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '80 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '84 DAY', false, 39, 78);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '71 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '76 DAY', false, 11, 78);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (79, 'Liam Jones', 85, 'Third Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '190 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '193 DAY', false, 7, 79);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '43 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '44 DAY', false, 38, 79);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '90 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '91 DAY', false, 46, 79);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (80, 'Emily Smith', 377, 'Oak Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '57 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '63 DAY', false, 44, 80);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '121 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '127 DAY', false, 22, 80);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '199 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '206 DAY', false, 19, 80);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 3, 'hotel3@hotels2.com', 257, 'Third Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (2, 11, 105.00, 1, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (32, 11, 122.50, 2, true, true, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (4, 11, 115.00, 3, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (21, 11, 145.00, 4, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (70, 11, 110.00, 5, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (81, 'Paul Perez', 11, 135, 'Metcalfe Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (81, 11);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (82, 'Elizabeth Ward', 11, 383, 'Oak Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (83, 'Ivana Johnson', 11, 26, 'Bank Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (84, 'Mary Sanchez', 11, 98, 'Third Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (85, 'Ashley Young', 11, 118, 'Main Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (86, 'Natalia Hernandez', 21, 'Third Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '16 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '18 DAY', false, 17, 86);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '167 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '170 DAY', false, 48, 86);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '193 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '199 DAY', false, 7, 86);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (87, 'Jon Miller', 361, 'Oak Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '6 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '9 DAY', false, 19, 87);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '198 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '203 DAY', false, 47, 87);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '35 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '42 DAY', false, 3, 87);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (88, 'Ashley Davis', 375, 'Metcalfe Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '205 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '206 DAY', false, 33, 88);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '135 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '136 DAY', false, 33, 88);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '138 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '139 DAY', false, 5, 88);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 4, 'hotel4@hotels2.com', 51, 'Laurier Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (78, 12, 160.00, 1, true, true, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (67, 12, 133.33, 2, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (83, 12, 176.67, 3, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (79, 12, 176.67, 4, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (53, 12, 166.67, 5, false, true, true, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (89, 'Susan Miller', 12, 12, 'Laurier Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (89, 12);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (90, 'Ivana Davis', 12, 155, 'Bank Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (91, 'Meg Reed', 12, 172, 'Bank Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (92, 'Elizabeth Miller', 12, 126, 'Oak Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (93, 'Ivana Williams', 12, 3, 'Willow Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (94, 'Susan Perez', 39, 'Main Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '147 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '149 DAY', false, 2, 94);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '117 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '120 DAY', false, 40, 94);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '166 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '169 DAY', false, 7, 94);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (95, 'Elizabeth Jones', 192, 'Metcalfe Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '83 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '86 DAY', false, 23, 95);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '194 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '201 DAY', false, 33, 95);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '123 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '126 DAY', false, 8, 95);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (96, 'Nick Price', 127, 'Bank Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '193 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '194 DAY', false, 5, 96);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '57 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '64 DAY', false, 13, 96);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '185 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '191 DAY', false, 54, 96);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 5, 'hotel5@hotels2.com', 293, 'Laurier Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (19, 13, 195.83, 1, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (54, 13, 216.67, 2, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (99, 13, 195.83, 3, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (70, 13, 187.50, 4, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (48, 13, 216.67, 5, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (97, 'Mary Hernandez', 13, 237, 'Third Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (97, 13);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (98, 'Jon Miller', 13, 209, 'Laurier Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (99, 'Ryan Perez', 13, 362, 'Willow Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (100, 'Ivana Price', 13, 261, 'Laurier Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (101, 'Mary Brown', 13, 279, 'Elm Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (102, 'Elizabeth Sanchez', 153, 'Metcalfe Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '76 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '79 DAY', false, 33, 102);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '190 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '191 DAY', false, 42, 102);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '165 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '169 DAY', false, 9, 102);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (103, 'Natalia Rogers', 153, 'Second Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '21 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '24 DAY', false, 46, 103);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '152 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '159 DAY', false, 36, 103);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '0 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '4 DAY', false, 61, 103);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (104, 'Nick Young', 45, 'Willow Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '23 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '27 DAY', false, 7, 104);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '153 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '156 DAY', false, 40, 104);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '95 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '96 DAY', false, 11, 104);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 1, 'hotel6@hotels2.com', 259, 'Bay Crescent', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (49, 14, 49.17, 1, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (32, 14, 35.83, 2, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (24, 14, 39.17, 3, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (86, 14, 42.50, 4, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (11, 14, 49.17, 5, false, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (105, 'Nick Williams', 14, 247, 'Elm Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (105, 14);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (106, 'Liam Rogers', 14, 163, 'Willow Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (107, 'Sarah Smith', 14, 275, 'Metcalfe Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (108, 'Meg Stewart', 14, 33, 'Oak Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (109, 'Emily Perez', 14, 71, 'Oak Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (110, 'Nick Price', 179, 'Bank Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '43 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '45 DAY', false, 69, 110);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '155 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '160 DAY', false, 3, 110);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '76 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '82 DAY', false, 20, 110);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (111, 'Liam Wilson', 5, 'Main Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '71 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '74 DAY', false, 1, 111);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '103 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '107 DAY', false, 33, 111);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '26 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '30 DAY', false, 51, 111);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (112, 'Meg Price', 207, 'Second Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '75 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '79 DAY', false, 50, 112);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '178 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '179 DAY', false, 10, 112);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '102 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '104 DAY', false, 51, 112);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 2, 'hotel7@hotels2.com', 262, 'Oak Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (69, 15, 81.67, 1, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (79, 15, 78.33, 2, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (26, 15, 86.67, 3, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (49, 15, 71.67, 4, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (93, 15, 76.67, 5, false, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (113, 'Natalia Price', 15, 6, 'First Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (113, 15);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (114, 'Elizabeth Wood', 15, 2, 'Metcalfe Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (115, 'Ryan Wilson', 15, 21, 'Main Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (116, 'David Williams', 15, 203, 'Metcalfe Boulevard', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (117, 'David Stewart', 15, 310, 'First Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (118, 'Andrew Cook', 208, 'Oak Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '5 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '11 DAY', false, 53, 118);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '209 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '210 DAY', false, 3, 118);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '114 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '116 DAY', false, 51, 118);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (119, 'Meg Miller', 277, 'Elm Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '121 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '124 DAY', false, 57, 119);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '101 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '108 DAY', false, 71, 119);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '22 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '29 DAY', false, 15, 119);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (120, 'Sarah Perez', 196, 'Third Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '83 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '90 DAY', false, 2, 120);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '2 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '4 DAY', false, 16, 120);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '9 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '15 DAY', false, 13, 120);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 3, 'hotel8@hotels2.com', 73, 'Pine Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (30, 16, 107.50, 1, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (37, 16, 140.00, 2, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (32, 16, 147.50, 3, true, true, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (38, 16, 100.00, 4, false, true, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (23, 16, 130.00, 5, true, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (121, 'Liam Reed', 16, 198, 'Pine Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (121, 16);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (122, 'Mary Cook', 16, 143, 'Bank Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (123, 'Nick Perez', 16, 177, 'Willow Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (124, 'Hudi Cook', 16, 339, 'Main Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (125, 'Andrew Smith', 16, 25, 'Third Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (126, 'Jon Stewart', 281, 'Second Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '157 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '163 DAY', false, 17, 126);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '195 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '197 DAY', false, 6, 126);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '174 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '176 DAY', false, 10, 126);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (127, 'Ryan Johnson', 246, 'Third Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '72 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '73 DAY', false, 9, 127);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '166 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '168 DAY', false, 50, 127);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '62 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '66 DAY', false, 23, 127);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (128, 'Susan Davis', 54, 'First Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '0 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '4 DAY', false, 45, 128);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '76 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '81 DAY', false, 61, 128);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '59 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '66 DAY', false, 31, 128);
INSERT INTO HotelChain(chain_name, email, street_number, street_name, city, province, country, zip) VALUES ('Hotels 3', 'hotel3@hotels.com', 86, 'Second Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 1, 'hotel1@hotels3.com', 16, 'Bay Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (15, 17, 35.00, 1, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (74, 17, 50.00, 2, true, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (98, 17, 42.50, 3, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (75, 17, 42.50, 4, true, true, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (71, 17, 35.00, 5, true, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (129, 'Elizabeth Reed', 17, 305, 'Main Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (129, 17);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (130, 'Jon Perez', 17, 267, 'Pine Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (131, 'Sahil Jones', 17, 261, 'Bank Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (132, 'Elizabeth Jones', 17, 352, 'Metcalfe Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (133, 'Hudi Reed', 17, 53, 'Metcalfe Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (134, 'Bob Perez', 345, 'Third Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '200 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '206 DAY', false, 57, 134);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '4 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '7 DAY', false, 1, 134);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '201 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '202 DAY', false, 32, 134);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (135, 'Sarah Brown', 133, 'Laurier Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '8 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '11 DAY', false, 80, 135);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '115 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '119 DAY', false, 4, 135);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '139 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '146 DAY', false, 40, 135);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (136, 'Liam Williams', 379, 'Laurier Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '106 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '110 DAY', false, 1, 136);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '118 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '119 DAY', false, 25, 136);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '10 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '12 DAY', false, 42, 136);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 2, 'hotel2@hotels3.com', 226, 'Bay Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (26, 18, 95.00, 1, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (90, 18, 98.33, 2, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (19, 18, 83.33, 3, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (66, 18, 80.00, 4, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (83, 18, 100.00, 5, true, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (137, 'Elizabeth Wilson', 18, 304, 'Bay Boulevard', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (137, 18);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (138, 'Mary Williams', 18, 366, 'Laurier Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (139, 'Emily Ward', 18, 80, 'Bank Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (140, 'Sarah Reed', 18, 295, 'Third Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (141, 'Nick Perez', 18, 15, 'Pine Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (142, 'Emily Sanchez', 126, 'Third Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '157 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '164 DAY', false, 41, 142);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '156 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '158 DAY', false, 76, 142);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '15 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '17 DAY', false, 85, 142);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (143, 'Andrew Brown', 41, 'Main Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '186 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '191 DAY', false, 57, 143);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '172 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '177 DAY', false, 29, 143);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '14 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '16 DAY', false, 23, 143);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (144, 'Elizabeth Miller', 64, 'First Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '32 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '36 DAY', false, 41, 144);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '114 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '119 DAY', false, 50, 144);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '1 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '6 DAY', false, 43, 144);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 3, 'hotel3@hotels3.com', 283, 'Second Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (95, 19, 140.00, 1, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (10, 19, 112.50, 2, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (3, 19, 122.50, 3, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (62, 19, 145.00, 4, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (89, 19, 125.00, 5, false, false, true, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (145, 'Alex Reed', 19, 113, 'Oak Crescent', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (145, 19);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (146, 'Emily Rogers', 19, 191, 'Laurier Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (147, 'Sarah Ward', 19, 338, 'Main Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (148, 'Natalia Rogers', 19, 88, 'Second Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (149, 'Andrew Johnson', 19, 75, 'Main Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (150, 'Mary Ward', 20, 'Second Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '101 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '102 DAY', false, 57, 150);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '120 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '124 DAY', false, 48, 150);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '178 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '185 DAY', false, 3, 150);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (151, 'Ryan Brown', 372, 'Second Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '49 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '56 DAY', false, 12, 151);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '140 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '146 DAY', false, 67, 151);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '78 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '81 DAY', false, 4, 151);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (152, 'Andrew Perez', 14, 'Oak Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '74 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '76 DAY', false, 17, 152);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '57 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '58 DAY', false, 74, 152);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '171 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '174 DAY', false, 19, 152);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 4, 'hotel4@hotels3.com', 234, 'Willow Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (10, 20, 183.33, 1, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (67, 20, 196.67, 2, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (98, 20, 173.33, 3, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (74, 20, 156.67, 4, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (90, 20, 193.33, 5, false, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (153, 'Natalia Miller', 20, 46, 'Third Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (153, 20);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (154, 'Susan Ward', 20, 178, 'Bay Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (155, 'David Cook', 20, 46, 'Main Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (156, 'Andrew Wilson', 20, 191, 'Bay Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (157, 'Ryan Davis', 20, 305, 'Willow Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (158, 'Hudi Young', 49, 'Pine Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '14 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '19 DAY', false, 67, 158);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '144 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '148 DAY', false, 19, 158);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '14 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '19 DAY', false, 16, 158);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (159, 'Alex Young', 360, 'Oak Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '65 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '68 DAY', false, 48, 159);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '60 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '66 DAY', false, 92, 159);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '118 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '119 DAY', false, 22, 159);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (160, 'Paul Brown', 30, 'Bay Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '88 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '91 DAY', false, 22, 160);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '127 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '129 DAY', false, 85, 160);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '85 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '87 DAY', false, 74, 160);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 5, 'hotel5@hotels3.com', 180, 'Second Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (44, 21, 245.83, 1, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (66, 21, 204.17, 2, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (55, 21, 241.67, 3, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (4, 21, 208.33, 4, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (72, 21, 195.83, 5, true, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (161, 'Andrew Wilson', 21, 218, 'Laurier Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (161, 21);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (162, 'Nick Jones', 21, 327, 'Metcalfe Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (163, 'Ashley Brown', 21, 109, 'Elm Boulevard', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (164, 'Paul Price', 21, 195, 'Elm Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (165, 'Andrew Davis', 21, 324, 'Main Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (166, 'Paul Williams', 259, 'Main Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '113 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '117 DAY', false, 102, 166);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '187 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '192 DAY', false, 13, 166);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '173 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '174 DAY', false, 7, 166);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (167, 'Sarah Perez', 31, 'Bank Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '94 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '95 DAY', false, 93, 167);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '145 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '148 DAY', false, 61, 167);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '128 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '134 DAY', false, 41, 167);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (168, 'David Reed', 180, 'Metcalfe Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '66 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '73 DAY', false, 73, 168);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '32 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '35 DAY', false, 47, 168);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '105 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '108 DAY', false, 20, 168);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 1, 'hotel6@hotels3.com', 299, 'Oak Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (93, 22, 48.33, 1, true, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (48, 22, 50.00, 2, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (49, 22, 49.17, 3, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (100, 22, 35.00, 4, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (41, 22, 40.83, 5, true, false, true, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (169, 'Susan Johnson', 22, 235, 'Third Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (169, 22);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (170, 'Bob Brown', 22, 335, 'Pine Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (171, 'Liam Sanchez', 22, 330, 'Metcalfe Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (172, 'Emily Price', 22, 153, 'Pine Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (173, 'Paul Ward', 22, 63, 'Willow Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (174, 'Andrew Brown', 232, 'Second Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '78 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '82 DAY', false, 22, 174);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '122 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '129 DAY', false, 100, 174);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '30 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '36 DAY', false, 91, 174);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (175, 'Ryan Davis', 88, 'Third Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '75 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '79 DAY', false, 18, 175);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '208 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '215 DAY', false, 20, 175);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '164 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '171 DAY', false, 96, 175);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (176, 'David Miller', 228, 'Pine Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '49 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '51 DAY', false, 10, 176);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '140 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '141 DAY', false, 27, 176);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '72 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '74 DAY', false, 38, 176);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 2, 'hotel7@hotels3.com', 228, 'Elm Way', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (27, 23, 68.33, 1, false, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (62, 23, 66.67, 2, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (97, 23, 88.33, 3, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (93, 23, 91.67, 4, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (64, 23, 76.67, 5, false, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (177, 'Bob Reed', 23, 170, 'Metcalfe Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (177, 23);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (178, 'Jon Perez', 23, 203, 'Main Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (179, 'Bob Miller', 23, 269, 'Main Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (180, 'Ivana Wood', 23, 72, 'Second Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (181, 'Andrew Williams', 23, 359, 'Metcalfe Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (182, 'Susan Stewart', 328, 'Willow Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '203 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '210 DAY', false, 49, 182);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '101 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '102 DAY', false, 82, 182);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '107 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '111 DAY', false, 115, 182);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (183, 'Ryan Price', 35, 'Willow Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '72 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '76 DAY', false, 97, 183);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '105 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '109 DAY', false, 31, 183);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '7 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '12 DAY', false, 29, 183);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (184, 'Ashley Reed', 240, 'Second Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '19 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '23 DAY', false, 89, 184);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '91 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '97 DAY', false, 82, 184);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '34 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '37 DAY', false, 66, 184);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 3, 'hotel8@hotels3.com', 12, 'Laurier Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (56, 24, 150.00, 1, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (29, 24, 130.00, 2, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (81, 24, 110.00, 3, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (33, 24, 120.00, 4, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (56, 24, 137.50, 5, false, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (185, 'Natalia Smith', 24, 271, 'Oak Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (185, 24);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (186, 'Jon Young', 24, 314, 'Willow Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (187, 'Elizabeth Wood', 24, 110, 'Bank Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (188, 'Elizabeth Miller', 24, 100, 'Willow Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (189, 'Paul Perez', 24, 224, 'Metcalfe Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (190, 'Sarah Wilson', 348, 'Second Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '19 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '23 DAY', false, 71, 190);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '116 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '117 DAY', false, 97, 190);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '138 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '144 DAY', false, 92, 190);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (191, 'Ivana Price', 184, 'Bay Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '15 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '22 DAY', false, 117, 191);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '166 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '167 DAY', false, 34, 191);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '50 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '52 DAY', false, 44, 191);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (192, 'Bob Perez', 270, 'Bank Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '137 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '140 DAY', false, 68, 192);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '0 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '4 DAY', false, 95, 192);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '91 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '94 DAY', false, 11, 192);
INSERT INTO HotelChain(chain_name, email, street_number, street_name, city, province, country, zip) VALUES ('Hotels 4', 'hotel4@hotels.com', 133, 'Willow Street', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 1, 'hotel1@hotels4.com', 228, 'Main Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (21, 25, 45.83, 1, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (15, 25, 44.17, 2, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (66, 25, 38.33, 3, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (55, 25, 35.00, 4, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (34, 25, 45.00, 5, true, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (193, 'Sahil Williams', 25, 382, 'Elm Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (193, 25);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (194, 'Sahil Jones', 25, 147, 'Elm Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (195, 'Emily Williams', 25, 87, 'Metcalfe Boulevard', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (196, 'Ryan Sanchez', 25, 327, 'Second Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (197, 'Liam Wilson', 25, 182, 'Bank Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (198, 'Liam Jones', 224, 'Bank Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '103 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '106 DAY', false, 105, 198);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '88 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '94 DAY', false, 20, 198);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '94 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '95 DAY', false, 49, 198);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (199, 'Bob Ward', 47, 'Bank Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '127 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '131 DAY', false, 62, 199);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '13 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '18 DAY', false, 4, 199);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '84 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '87 DAY', false, 33, 199);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (200, 'Emily Reed', 323, 'Willow Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '139 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '142 DAY', false, 86, 200);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '113 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '118 DAY', false, 117, 200);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '5 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '10 DAY', false, 45, 200);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 2, 'hotel2@hotels4.com', 54, 'Elm Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (37, 26, 73.33, 1, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (21, 26, 88.33, 2, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (66, 26, 86.67, 3, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (53, 26, 91.67, 4, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (10, 26, 90.00, 5, true, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (201, 'Emily Williams', 26, 350, 'Third Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (201, 26);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (202, 'Meg Miller', 26, 2, 'Main Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (203, 'Paul Davis', 26, 171, 'Bank Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (204, 'Emily Rogers', 26, 277, 'Bay Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (205, 'Ivana Miller', 26, 165, 'Pine Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (206, 'Andrew Perez', 390, 'Pine Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '51 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '54 DAY', false, 108, 206);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '101 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '103 DAY', false, 32, 206);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '86 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '91 DAY', false, 6, 206);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (207, 'Hudi Young', 363, 'Laurier Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '110 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '116 DAY', false, 108, 207);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '83 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '84 DAY', false, 50, 207);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '192 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '198 DAY', false, 122, 207);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (208, 'Liam Wood', 334, 'Laurier Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '45 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '52 DAY', false, 36, 208);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '58 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '65 DAY', false, 62, 208);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '119 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '121 DAY', false, 22, 208);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 3, 'hotel3@hotels4.com', 82, 'Second Street', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (89, 27, 140.00, 1, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (72, 27, 127.50, 2, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (29, 27, 140.00, 3, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (95, 27, 122.50, 4, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (66, 27, 110.00, 5, true, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (209, 'Meg Reed', 27, 33, 'Bank Crescent', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (209, 27);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (210, 'David Price', 27, 193, 'First Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (211, 'Emily Reed', 27, 342, 'Laurier Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (212, 'Susan Hernandez', 27, 117, 'Elm Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (213, 'Natalia Stewart', 27, 45, 'Third Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (214, 'Bob Perez', 11, 'Oak Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '103 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '110 DAY', false, 58, 214);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '7 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '13 DAY', false, 3, 214);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '11 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '17 DAY', false, 64, 214);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (215, 'Alex Rogers', 393, 'Second Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '97 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '98 DAY', false, 61, 215);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '134 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '136 DAY', false, 81, 215);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '20 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '21 DAY', false, 72, 215);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (216, 'Nick Jones', 22, 'Oak Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '170 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '177 DAY', false, 103, 216);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '4 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '10 DAY', false, 4, 216);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '100 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '102 DAY', false, 133, 216);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 4, 'hotel4@hotels4.com', 150, 'Second Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (54, 28, 160.00, 1, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (31, 28, 190.00, 2, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (71, 28, 150.00, 3, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (3, 28, 190.00, 4, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (60, 28, 163.33, 5, true, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (217, 'David Wilson', 28, 261, 'First Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (217, 28);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (218, 'Elizabeth Smith', 28, 155, 'Second Crescent', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (219, 'Ashley Davis', 28, 10, 'Third Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (220, 'Ivana Sanchez', 28, 43, 'Bank Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (221, 'Nick Williams', 28, 55, 'Main Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (222, 'Ryan Brown', 227, 'First Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '5 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '9 DAY', false, 32, 222);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '200 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '205 DAY', false, 80, 222);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '169 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '170 DAY', false, 76, 222);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (223, 'Ryan Davis', 361, 'Pine Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '194 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '195 DAY', false, 15, 223);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '64 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '67 DAY', false, 121, 223);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '20 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '26 DAY', false, 58, 223);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (224, 'Nick Smith', 266, 'First Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '125 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '128 DAY', false, 107, 224);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '5 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '12 DAY', false, 60, 224);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '169 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '176 DAY', false, 122, 224);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 5, 'hotel5@hotels4.com', 199, 'Laurier Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (73, 29, 195.83, 1, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (32, 29, 229.17, 2, false, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (81, 29, 237.50, 3, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (56, 29, 245.83, 4, false, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (90, 29, 237.50, 5, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (225, 'Emily Young', 29, 280, 'First Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (225, 29);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (226, 'Natalia Stewart', 29, 70, 'Bay Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (227, 'Ashley Smith', 29, 45, 'Willow Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (228, 'Meg Wilson', 29, 100, 'Willow Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (229, 'Alex Rogers', 29, 142, 'Pine Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (230, 'Meg Johnson', 394, 'Willow Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '104 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '108 DAY', false, 124, 230);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '153 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '159 DAY', false, 49, 230);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '34 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '40 DAY', false, 107, 230);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (231, 'Susan Miller', 170, 'Elm Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '67 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '71 DAY', false, 76, 231);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '86 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '92 DAY', false, 92, 231);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '57 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '64 DAY', false, 82, 231);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (232, 'Jon Rogers', 263, 'Second Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '191 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '193 DAY', false, 6, 232);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '121 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '127 DAY', false, 94, 232);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '56 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '62 DAY', false, 131, 232);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 1, 'hotel6@hotels4.com', 243, 'Bay Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (79, 30, 34.17, 1, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (66, 30, 43.33, 2, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (67, 30, 39.17, 3, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (84, 30, 50.00, 4, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (48, 30, 37.50, 5, true, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (233, 'Paul Rogers', 30, 342, 'Second Crescent', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (233, 30);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (234, 'Ivana Cook', 30, 5, 'Main Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (235, 'Andrew Hernandez', 30, 373, 'First Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (236, 'Ivana Rogers', 30, 347, 'Willow Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (237, 'Meg Stewart', 30, 58, 'Bay Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (238, 'Andrew Hernandez', 137, 'Bank Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '9 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '10 DAY', false, 133, 238);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '93 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '98 DAY', false, 140, 238);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '36 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '43 DAY', false, 133, 238);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (239, 'Andrew Williams', 219, 'Bay Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '148 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '151 DAY', false, 39, 239);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '3 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '9 DAY', false, 90, 239);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '8 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '15 DAY', false, 51, 239);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (240, 'Bob Brown', 5, 'Metcalfe Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '165 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '166 DAY', false, 58, 240);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '9 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '15 DAY', false, 59, 240);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '99 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '101 DAY', false, 100, 240);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 2, 'hotel7@hotels4.com', 283, 'First Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (1, 31, 96.67, 1, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (1, 31, 88.33, 2, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (38, 31, 98.33, 3, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (77, 31, 80.00, 4, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (23, 31, 83.33, 5, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (241, 'Ivana Williams', 31, 70, 'Bay Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (241, 31);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (242, 'Meg Rogers', 31, 6, 'Elm Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (243, 'Jon Stewart', 31, 340, 'Main Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (244, 'Susan Smith', 31, 79, 'Bank Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (245, 'Liam Ward', 31, 14, 'First Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (246, 'Elizabeth Wood', 27, 'Third Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '93 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '98 DAY', false, 59, 246);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '3 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '9 DAY', false, 115, 246);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '148 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '155 DAY', false, 65, 246);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (247, 'Jon Smith', 71, 'Second Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '180 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '184 DAY', false, 16, 247);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '13 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '19 DAY', false, 84, 247);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '176 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '177 DAY', false, 91, 247);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (248, 'David Smith', 146, 'Main Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '23 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '26 DAY', false, 143, 248);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '119 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '121 DAY', false, 103, 248);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '201 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '207 DAY', false, 17, 248);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 3, 'hotel8@hotels4.com', 67, 'Bay Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (45, 32, 145.00, 1, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (21, 32, 105.00, 2, false, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (63, 32, 147.50, 3, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (5, 32, 122.50, 4, true, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (37, 32, 110.00, 5, true, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (249, 'Natalia Smith', 32, 335, 'Oak Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (249, 32);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (250, 'Mary Rogers', 32, 252, 'Laurier Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (251, 'Liam Hernandez', 32, 82, 'Second Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (252, 'David Johnson', 32, 184, 'Oak Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (253, 'Nick Rogers', 32, 137, 'First Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (254, 'Elizabeth Reed', 280, 'Oak Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '186 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '190 DAY', false, 132, 254);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '90 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '94 DAY', false, 141, 254);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '153 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '154 DAY', false, 15, 254);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (255, 'Nick Hernandez', 272, 'Third Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '4 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '6 DAY', false, 59, 255);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '156 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '162 DAY', false, 38, 255);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '201 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '204 DAY', false, 128, 255);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (256, 'David Wilson', 56, 'Bay Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '172 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '175 DAY', false, 50, 256);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '24 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '30 DAY', false, 77, 256);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '155 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '160 DAY', false, 86, 256);
INSERT INTO HotelChain(chain_name, email, street_number, street_name, city, province, country, zip) VALUES ('Hotels 5', 'hotel5@hotels.com', 183, 'Main Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 1, 'hotel1@hotels5.com', 122, 'Metcalfe Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (8, 33, 45.00, 1, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (53, 33, 35.83, 2, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (10, 33, 46.67, 3, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (10, 33, 47.50, 4, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (16, 33, 45.00, 5, true, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (257, 'Sarah Cook', 33, 289, 'Oak Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (257, 33);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (258, 'Meg Young', 33, 354, 'Bay Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (259, 'Ashley Davis', 33, 327, 'Willow Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (260, 'Ashley Cook', 33, 12, 'Second Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (261, 'Sarah Wilson', 33, 47, 'Bank Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (262, 'Bob Williams', 301, 'Bank Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '118 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '119 DAY', false, 159, 262);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '120 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '126 DAY', false, 149, 262);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '133 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '137 DAY', false, 132, 262);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (263, 'Meg Stewart', 110, 'Elm Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '43 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '45 DAY', false, 62, 263);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '160 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '162 DAY', false, 72, 263);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '149 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '152 DAY', false, 67, 263);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (264, 'Nick Wilson', 42, 'Willow Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '165 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '170 DAY', false, 64, 264);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '175 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '182 DAY', false, 110, 264);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '9 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '13 DAY', false, 125, 264);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 2, 'hotel2@hotels5.com', 28, 'Oak Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (51, 34, 88.33, 1, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (41, 34, 96.67, 2, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (37, 34, 100.00, 3, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (43, 34, 86.67, 4, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (84, 34, 86.67, 5, true, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (265, 'Sahil Brown', 34, 221, 'Willow Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (265, 34);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (266, 'Ryan Williams', 34, 328, 'Third Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (267, 'Alex Cook', 34, 73, 'First Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (268, 'Emily Cook', 34, 366, 'First Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (269, 'Liam Wilson', 34, 304, 'Bay Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (270, 'Nick Rogers', 142, 'Pine Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '30 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '36 DAY', false, 19, 270);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '4 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '7 DAY', false, 160, 270);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '199 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '200 DAY', false, 55, 270);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (271, 'Ashley Stewart', 383, 'First Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '40 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '47 DAY', false, 14, 271);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '14 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '17 DAY', false, 143, 271);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '92 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '98 DAY', false, 7, 271);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (272, 'Ryan Miller', 104, 'First Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '33 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '39 DAY', false, 120, 272);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '39 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '43 DAY', false, 156, 272);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '37 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '44 DAY', false, 105, 272);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 3, 'hotel3@hotels5.com', 127, 'First Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (11, 35, 100.00, 1, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (21, 35, 112.50, 2, false, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (83, 35, 100.00, 3, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (16, 35, 125.00, 4, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (60, 35, 125.00, 5, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (273, 'Jon Williams', 35, 22, 'First Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (273, 35);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (274, 'Jon Davis', 35, 114, 'Bay Crescent', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (275, 'Natalia Rogers', 35, 109, 'Metcalfe Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (276, 'Alex Brown', 35, 277, 'Laurier Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (277, 'Elizabeth Wood', 35, 83, 'First Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (278, 'Susan Wood', 101, 'Third Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '102 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '108 DAY', false, 54, 278);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '17 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '20 DAY', false, 37, 278);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '11 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '16 DAY', false, 53, 278);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (279, 'Bob Smith', 385, 'Pine Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '195 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '198 DAY', false, 56, 279);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '139 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '141 DAY', false, 4, 279);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '63 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '67 DAY', false, 2, 279);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (280, 'Ivana Jones', 283, 'Bank Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '205 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '209 DAY', false, 91, 280);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '42 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '46 DAY', false, 31, 280);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '4 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '7 DAY', false, 153, 280);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 4, 'hotel4@hotels5.com', 63, 'Bank Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (74, 36, 190.00, 1, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (92, 36, 140.00, 2, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (99, 36, 176.67, 3, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (24, 36, 180.00, 4, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (5, 36, 176.67, 5, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (281, 'Ivana Hernandez', 36, 266, 'Main Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (281, 36);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (282, 'Mary Jones', 36, 181, 'Metcalfe Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (283, 'Andrew Brown', 36, 187, 'Third Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (284, 'Mary Davis', 36, 267, 'Willow Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (285, 'Andrew Stewart', 36, 46, 'Metcalfe Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (286, 'Susan Wilson', 215, 'Main Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '102 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '106 DAY', false, 104, 286);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '11 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '14 DAY', false, 111, 286);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '50 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '57 DAY', false, 67, 286);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (287, 'Andrew Reed', 343, 'Pine Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '104 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '106 DAY', false, 93, 287);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '68 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '71 DAY', false, 53, 287);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '163 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '168 DAY', false, 61, 287);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (288, 'Nick Davis', 193, 'Willow Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '184 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '186 DAY', false, 176, 288);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '187 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '194 DAY', false, 107, 288);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '142 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '143 DAY', false, 158, 288);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 5, 'hotel5@hotels5.com', 171, 'Bay Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (83, 37, 220.83, 1, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (20, 37, 225.00, 2, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (94, 37, 179.17, 3, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (53, 37, 225.00, 4, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (60, 37, 216.67, 5, true, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (289, 'Elizabeth Perez', 37, 292, 'Pine Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (289, 37);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (290, 'Ashley Cook', 37, 366, 'Oak Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (291, 'Meg Jones', 37, 375, 'Pine Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (292, 'Ashley Cook', 37, 350, 'Bay Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (293, 'Emily Johnson', 37, 207, 'Elm Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (294, 'Andrew Stewart', 367, 'First Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '71 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '76 DAY', false, 180, 294);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '82 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '87 DAY', false, 161, 294);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '135 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '139 DAY', false, 112, 294);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (295, 'Elizabeth Price', 186, 'Pine Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '11 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '12 DAY', false, 32, 295);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '95 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '97 DAY', false, 149, 295);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '24 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '26 DAY', false, 87, 295);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (296, 'Elizabeth Ward', 352, 'Laurier Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '8 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '14 DAY', false, 21, 296);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '88 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '92 DAY', false, 74, 296);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '23 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '28 DAY', false, 139, 296);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 1, 'hotel6@hotels5.com', 118, 'Laurier Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (35, 38, 39.17, 1, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (3, 38, 44.17, 2, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (86, 38, 48.33, 3, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (90, 38, 34.17, 4, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (51, 38, 46.67, 5, false, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (297, 'Ryan Perez', 38, 312, 'Laurier Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (297, 38);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (298, 'Paul Johnson', 38, 119, 'Metcalfe Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (299, 'Emily Perez', 38, 51, 'Elm Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (300, 'Hudi Brown', 38, 207, 'Metcalfe Boulevard', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (301, 'Ashley Miller', 38, 74, 'Metcalfe Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (302, 'Mary Ward', 260, 'Bay Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '2 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '8 DAY', false, 11, 302);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '153 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '154 DAY', false, 2, 302);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '11 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '18 DAY', false, 39, 302);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (303, 'Mary Reed', 348, 'Elm Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '144 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '148 DAY', false, 160, 303);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '145 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '147 DAY', false, 32, 303);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '181 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '188 DAY', false, 36, 303);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (304, 'Alex Price', 93, 'Third Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '184 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '187 DAY', false, 119, 304);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '85 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '89 DAY', false, 178, 304);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '53 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '55 DAY', false, 8, 304);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 2, 'hotel7@hotels5.com', 138, 'Bay Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (29, 39, 66.67, 1, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (94, 39, 95.00, 2, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (86, 39, 98.33, 3, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (6, 39, 85.00, 4, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (83, 39, 90.00, 5, false, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (305, 'David Reed', 39, 75, 'Metcalfe Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (305, 39);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (306, 'Elizabeth Wood', 39, 257, 'Elm Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (307, 'Meg Wilson', 39, 193, 'Metcalfe Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (308, 'Sahil Perez', 39, 106, 'Second Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (309, 'Susan Miller', 39, 369, 'Second Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (310, 'Bob Young', 338, 'Laurier Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '10 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '11 DAY', false, 167, 310);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '159 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '160 DAY', false, 157, 310);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '92 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '95 DAY', false, 104, 310);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (311, 'Liam Hernandez', 264, 'Pine Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '127 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '133 DAY', false, 156, 311);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '150 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '156 DAY', false, 13, 311);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '0 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '6 DAY', false, 94, 311);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (312, 'Bob Sanchez', 329, 'Elm Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '3 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '10 DAY', false, 195, 312);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '128 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '132 DAY', false, 120, 312);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '134 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '141 DAY', false, 128, 312);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 3, 'hotel8@hotels5.com', 160, 'Bank Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (13, 40, 115.00, 1, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (75, 40, 130.00, 2, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (29, 40, 127.50, 3, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (75, 40, 135.00, 4, false, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (62, 40, 140.00, 5, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (313, 'Susan Davis', 40, 364, 'Main Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (313, 40);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (314, 'Meg Young', 40, 26, 'Bank Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (315, 'Andrew Stewart', 40, 258, 'Metcalfe Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (316, 'Andrew Price', 40, 352, 'Oak Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (317, 'Mary Stewart', 40, 321, 'Willow Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (318, 'Mary Rogers', 273, 'Bay Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '101 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '108 DAY', false, 38, 318);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '19 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '20 DAY', false, 107, 318);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '59 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '64 DAY', false, 198, 318);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (319, 'Mary Price', 277, 'Elm Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '52 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '56 DAY', false, 3, 319);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '122 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '125 DAY', false, 59, 319);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '209 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '210 DAY', false, 109, 319);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (320, 'Ivana Hernandez', 369, 'Bay Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '36 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '42 DAY', false, 65, 320);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '89 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '94 DAY', false, 122, 320);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 YEAR' + INTERVAL '114 DAY', now() + INTERVAL '1 YEAR' + INTERVAL '116 DAY', false, 1, 320);
INSERT INTO Amenity(room_id, name, description) VALUES (1, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (1, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (1, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (2, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (2, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (3, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (3, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (3, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (3, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (4, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (4, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (4, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (4, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (5, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (6, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (6, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (6, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (6, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (6, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (7, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (7, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (7, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (7, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (8, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (8, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (8, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (8, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (8, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (8, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (9, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (9, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (9, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (10, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (10, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (11, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (11, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (11, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (11, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (11, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (11, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (12, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (12, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (12, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (12, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (13, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (13, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (13, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (13, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (14, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (14, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (14, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (15, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (15, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (15, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (15, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (16, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (16, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (16, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (16, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (17, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (17, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (17, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (17, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (17, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (18, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (18, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (18, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (18, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (19, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (19, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (20, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (20, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (20, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (20, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (21, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (21, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (21, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (21, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (22, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (22, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (22, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (23, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (23, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (24, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (24, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (24, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (24, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (24, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (25, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (25, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (25, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (26, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (26, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (26, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (27, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (27, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (27, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (27, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (28, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (28, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (28, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (28, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (28, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (29, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (29, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (29, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (30, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (30, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (30, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (31, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (31, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (31, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (32, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (32, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (32, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (33, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (33, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (33, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (34, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (34, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (34, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (34, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (35, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (35, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (36, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (36, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (36, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (36, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (37, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (37, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (37, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (37, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (37, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (38, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (38, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (38, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (38, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (39, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (40, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (41, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (41, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (41, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (41, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (41, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (43, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (43, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (43, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (43, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (43, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (44, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (44, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (45, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (46, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (47, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (47, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (47, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (47, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (47, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (48, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (48, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (48, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (48, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (48, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (49, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (49, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (49, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (50, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (50, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (50, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (51, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (51, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (51, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (52, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (52, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (52, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (52, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (53, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (54, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (54, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (54, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (55, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (56, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (56, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (57, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (57, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (57, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (57, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (57, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (58, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (58, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (58, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (58, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (59, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (60, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (60, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (60, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (60, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (61, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (61, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (62, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (62, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (63, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (63, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (63, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (63, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (63, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (64, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (64, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (65, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (66, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (67, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (67, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (67, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (67, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (68, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (68, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (69, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (69, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (69, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (70, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (70, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (70, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (71, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (71, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (72, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (72, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (72, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (73, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (73, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (73, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (73, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (74, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (74, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (74, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (74, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (75, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (75, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (75, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (76, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (76, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (76, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (76, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (77, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (77, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (77, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (78, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (79, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (79, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (79, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (79, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (80, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (80, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (81, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (81, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (82, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (82, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (82, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (82, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (83, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (83, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (83, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (83, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (83, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (84, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (84, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (84, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (84, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (85, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (85, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (85, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (85, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (86, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (86, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (86, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (87, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (87, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (88, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (88, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (88, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (89, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (89, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (89, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (89, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (90, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (90, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (90, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (91, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (91, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (92, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (92, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (92, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (92, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (92, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (93, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (93, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (93, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (94, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (94, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (94, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (94, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (95, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (95, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (96, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (96, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (96, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (97, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (97, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (97, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (97, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (98, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (98, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (98, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (98, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (99, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (99, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (99, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (99, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (100, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (100, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (100, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (100, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (100, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (101, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (102, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (102, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (103, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (103, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (103, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (103, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (104, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (104, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (104, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (106, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (107, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (107, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (107, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (107, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (108, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (108, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (109, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (109, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (109, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (109, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (110, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (110, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (110, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (110, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (110, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (111, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (111, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (112, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (112, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (113, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (113, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (113, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (113, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (114, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (114, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (115, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (115, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (115, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (116, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (116, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (116, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (117, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (117, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (117, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (117, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (117, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (118, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (118, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (118, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (118, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (119, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (120, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (120, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (120, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (121, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (121, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (121, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (121, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (122, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (122, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (122, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (123, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (123, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (123, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (124, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (124, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (125, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (125, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (125, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (126, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (126, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (126, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (126, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (127, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (127, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (128, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (128, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (128, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (128, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (129, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (129, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (129, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (129, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (130, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (130, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (130, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (131, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (131, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (131, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (132, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (132, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (132, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (132, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (132, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (132, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (133, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (133, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (133, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (133, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (134, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (134, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (134, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (134, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (135, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (135, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (135, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (136, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (136, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (136, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (137, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (137, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (137, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (138, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (138, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (138, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (139, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (139, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (140, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (140, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (140, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (140, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (141, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (141, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (142, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (142, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (142, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (143, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (143, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (143, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (144, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (144, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (145, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (145, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (145, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (146, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (146, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (146, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (146, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (146, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (147, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (147, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (147, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (148, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (148, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (148, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (149, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (149, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (149, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (150, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (150, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (150, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (151, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (151, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (151, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (151, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (151, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (152, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (152, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (153, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (153, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (153, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (154, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (155, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (155, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (156, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (156, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (156, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (156, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (157, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (157, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (157, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (157, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (157, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (157, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (158, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (158, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (158, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (158, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (159, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (159, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (159, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (159, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (159, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (160, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (160, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (160, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (160, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (161, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (162, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (162, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (162, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (162, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (163, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (163, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (163, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (164, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (165, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (165, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (166, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (166, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (166, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (166, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (167, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (167, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (167, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (167, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (168, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (168, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (168, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (168, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (169, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (169, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (170, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (170, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (171, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (171, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (172, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (172, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (172, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (172, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (172, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (173, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (173, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (173, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (173, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (174, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (174, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (174, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (174, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (174, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (174, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (176, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (176, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (176, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (176, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (177, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (177, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (177, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (178, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (178, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (178, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (179, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (179, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (179, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (180, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (180, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (180, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (180, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (180, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (181, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (181, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (181, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (182, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (182, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (182, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (182, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (182, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (183, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (183, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (183, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (184, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (184, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (184, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (185, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (185, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (186, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (186, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (186, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (187, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (187, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (188, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (188, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (189, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (189, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (189, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (190, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (190, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (190, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (191, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (191, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (191, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (191, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (192, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (192, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (193, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (193, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (193, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (193, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (194, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (194, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (194, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (194, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (195, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (195, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (195, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (195, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (196, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (196, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (196, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (197, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (197, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (198, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (198, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (198, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (199, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (199, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (199, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (200, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (200, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (200, 'Air conditioner', NULL);
INSERT INTO Role(name, description) VALUES ('Custodian', NULL);
INSERT INTO Role(name, description) VALUES ('Maid', NULL);
INSERT INTO Role(name, description) VALUES ('Bellboy', NULL);
INSERT INTO Role(name, description) VALUES ('Front Desk Person', NULL);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (2, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (3, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (4, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (5, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (10, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (11, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (12, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (13, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (18, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (19, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (20, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (21, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (26, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (27, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (28, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (29, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (34, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (35, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (36, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (37, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (42, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (43, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (44, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (45, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (50, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (51, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (52, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (53, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (58, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (59, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (60, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (61, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (66, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (67, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (68, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (69, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (74, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (75, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (76, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (77, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (82, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (83, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (84, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (85, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (90, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (91, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (92, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (93, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (98, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (99, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (100, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (101, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (106, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (107, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (108, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (109, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (114, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (115, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (116, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (117, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (122, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (123, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (124, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (125, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (130, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (131, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (132, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (133, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (138, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (139, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (140, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (141, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (146, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (147, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (148, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (149, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (154, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (155, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (156, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (157, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (162, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (163, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (164, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (165, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (170, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (171, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (172, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (173, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (178, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (179, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (180, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (181, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (186, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (187, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (188, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (189, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (194, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (195, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (196, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (197, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (202, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (203, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (204, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (205, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (210, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (211, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (212, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (213, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (218, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (219, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (220, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (221, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (226, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (227, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (228, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (229, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (234, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (235, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (236, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (237, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (242, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (243, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (244, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (245, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (250, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (251, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (252, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (253, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (258, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (259, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (260, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (261, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (266, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (267, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (268, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (269, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (274, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (275, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (276, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (277, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (282, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (283, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (284, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (285, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (290, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (291, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (292, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (293, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (298, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (299, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (300, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (301, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (306, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (307, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (308, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (309, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (314, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (315, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (316, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (317, 3);
INSERT INTO ChainPhoneNumber(chain_id, phone_number) VALUES (1, '2252891910');
INSERT INTO ChainPhoneNumber(chain_id, phone_number) VALUES (2, '7516516631');
INSERT INTO ChainPhoneNumber(chain_id, phone_number) VALUES (3, '6731359431');
INSERT INTO ChainPhoneNumber(chain_id, phone_number) VALUES (4, '4167932357');
INSERT INTO ChainPhoneNumber(chain_id, phone_number) VALUES (5, '1649006007');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (1, '2207524397');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (2, '1080992480');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (3, '8570343282');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (4, '7824669473');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (5, '3143018247');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (6, '1678734262');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (7, '1646426504');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (8, '2370172242');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (9, '6812252543');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (10, '8723557262');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (11, '3846466711');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (12, '3186073641');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (13, '2430024507');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (14, '1282107523');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (15, '5281940651');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (16, '3261010216');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (17, '2424996542');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (18, '7713447427');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (19, '2021800001');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (20, '2838514957');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (21, '1843670870');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (22, '8081233061');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (23, '9341486812');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (24, '3157666744');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (25, '1329359565');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (26, '5997468106');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (27, '7933632108');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (28, '1196173247');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (29, '5656427351');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (30, '1769152639');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (31, '1799976865');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (32, '8388873570');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (33, '8138610253');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (34, '2073011314');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (35, '9847002803');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (36, '8329231481');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (37, '8611621601');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (38, '5461706893');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (39, '2720379101');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (40, '7761947782');
