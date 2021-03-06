DROP VIEW IF EXISTS employeeroles;
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
    hc.chain_id = h.chain_id; 