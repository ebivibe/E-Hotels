insert into HotelChain(chain_name, email, street_number, street_name, unit, city, province, country, zip) values(
    'test', 'test@test.ca', 1, 'test ave', 'A', 'ottatest', 'ontestio', 'canatest', 'testzip'
);
insert into Hotel(chain_id, category, email, street_number, street_name, unit, city, province, country, zip) values(
    1, 2, 'test2@test.ca',  2, 'test2 ave', 'B', 'ottatest2', 'ontestio2', 'canatest2', 'testzip2'
);

insert into employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) values (
    565, 'Steve', 1, 1235, 'Avenue Street', 'Ottawa', 'Ontario', 'Canada', 'K1S5J6', 'BobIsAName'
);

insert into customer(ssn, name, street_number, street_name, city, province, country, zip, password) values (
    555, 'Joe', 12345, 'Avenue Street', 'Ottawa', 'Ontario', 'Canada', 'k1S5J6', 'SteveIsAName'
);

insert into room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) values (
    132, 1, 17.95, 2, true, true, false, false
);

insert into bookingrental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn, employee_ssn)
	values (now(), now(), now() + INTERVAL '1 DAY', false, 1, 555, 565);