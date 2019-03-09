CREATE TABLE HotelChain (
 chain_id SERIAL PRIMARY KEY,
 chain_name VARCHAR (255) NOT NULL,
 num_hotels INT NOT NULL,
 email VARCHAR(255) NOT NULL,
 street_number INT NOT NULL,
 unit VARCHAR(255),
 city VARCHAR(255) NOT NULL,
 province VARCHAR(255) NOT NULL,
 country VARCHAR(255) NOT NULL,
 zip VARCHAR(255) NOT NULL,
 CONSTRAINT street_number CHECK (street_number > 0),
 CONSTRAINT num_hotels CHECK (num_hotels >= 0)
);

CREATE TABLE ChainPhoneNumber(
    chain_id INT REFERENCES HotelChain(chain_id),
    phone_number VARCHAR(255) NOT NULL,
    PRIMARY KEY(chain_id, phone_number)
);


CREATE TABLE Hotel (
 hotel_id SERIAL PRIMARY KEY,
 chain_id INTEGER REFERENCES HotelChain(chain_id),
 category INT NOT NULL,
 email VARCHAR(255) NOT NULL,
 street_number INT NOT NULL,
 unit VARCHAR(255),
 city VARCHAR(255) NOT NULL,
 province VARCHAR(255) NOT NULL,
 country VARCHAR(255) NOT NULL,
 zip VARCHAR(255) NOT NULL,
 CONSTRAINT street_number check (street_number > 0),
 CONSTRAINT categoryabove check (category >= 1),
 CONSTRAINT categorybelow check (category <= 5)
);

CREATE TABLE HotelPhoneNumber(
    hotel_id INT REFERENCES Hotel(hotel_id),
    phone_number VARCHAR(255) NOT NULL,
    PRIMARY KEY(hotel_id, phone_number)
);

CREATE TABLE Room(
  room_id SERIAL PRIMARY KEY,
  room_number INT NOT NULL,
  hotel_id INT REFERENCES Hotel(hotel_id),
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

CREATE TABLE Amenity(
    room_id INT REFERENCES Room(room_id),
    name VARCHAR(255) NOT NULL,
    description VARCHAR(255),
    PRIMARY KEY(room_id, name)
);

CREATE TABLE Employee (
 SSN INT PRIMARY KEY,
 name VARCHAR (255) NOT NULL,
 hotel_id INT REFERENCES Hotel(hotel_id),
 street_number INT NOT NULL,
 unit VARCHAR(255),
 city VARCHAR(255) NOT NULL,
 province VARCHAR(255) NOT NULL,
 country VARCHAR(255) NOT NULL,
 zip VARCHAR(255) NOT NULL,
 password VARCHAR(255) NOT NULL,
 CONSTRAINT street_number CHECK (street_number >= 0),
 CONSTRAINT password CHECK (char_length(password) >= 5)
);

CREATE TABLE Manages(
 SSN INT REFERENCES Employee(SSN),
 hotel_id INT REFERENCES Hotel(hotel_id)
);


CREATE TABLE Role(
 role_id SERIAL PRIMARY KEY,
 name VARCHAR(255) NOT NULL,
 description VARCHAR(255)
);

CREATE TABLE EmployeeRole(
 employee_id INT REFERENCES Employee(SSN),
 role_id INT REFERENCES Role(role_id)
 PRIMARY KEY(employee_id, role_id)
);


CREATE TABLE Archive (
    archive_id SERIAL PRIMARY KEY,
    room_number INT NOT NULL,
    street_number INT NOT NULL,
    street_name VARCHAR(255) NOT NULL,
    unit VARCHAR(255),
    hotel_city VARCHAR(255) NOT NULL,
    hotel_state VARCHAR(255) NOT NULL,
    hotel_zip VARCHAR(255) NOT NULL,
    hotel_country VARCHAR(255) NOT NULL,
    check_in_date TIMESTAMP NOT NULL,
    hotel_chain VARCHAR(255) NOT NULL,
    reservation_date TIMESTAMP,
    check_out_date TIMESTAMP NOT NULL,
    customer_ssn INT NOT NULL,
    employee_ssn INT NOT NULL,
    CONSTRAINT archive_id CHECK (archive_id > 0),
    CONSTRAINT street_number CHECK (street_number > 0),
    CONSTRAINT room_number CHECK (room_number > 0)
);

