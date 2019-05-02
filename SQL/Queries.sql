/* For this file variables in square brackets are php variables in our application

/*--------- Queries for Customer -------*/

/*Log in*/
SELECT exists(Select * FROM public.Customer where SSN=['username'] and password=['password']);


/* Sign up*/

insert into public.Customer(SSN, name, street_number, street_name, unit, city, province, country, zip, password) values(
['ssn'], '['name']', ['streetnumber'], '['streetname']', '['unit']', '['city']',
'['province']', '['country']', '['zip']',
'['password']');


/*Make a booking*/
Insert into public.BookingRental(reservation_date, check_in_date, check_out_date, checked_in, paid, room_id, customer_ssn, employee_ssn) values(
now(), '['check_in_date']','['check_out_date']', false,
false , '['room_id']', '['user_id']', null );


/* View bookings*/
SELECT * FROM public.bookinginfo where customer_ssn = ['user_id']  order by booking_id;

/*Find a room*/
Select room_id, room_number, chain_name, street_number, street_name, unit,
city, province, country, zip, capacity, price, category, num_rooms from roominfo r where damages=false
 and capacity = ['capacity']
 and category >= ['category']
 and city ILIKE '% ['city'] %\'
 and chain_name ILIKE '%'['chain_name']'%\'
 and num_rooms =['num_rooms']
 and price <= ['price']
 and (select b.room_id from BookingRental b where 
 (SELECT (TIMESTAMP '['start_date']', TIMESTAMP '['end_date']')
OVERLAPS (check_in_date, check_out_date)) and b.room_id = r.room_id limit 1) is null;

/*See available rooms per area*/
Select COUNT(room_id) as num, city, province, country 
from roomarea r where damages=false and 
(select b.room_id from BookingRental b where (SELECT (TIMESTAMP '['start_date']', 
TIMESTAMP '['end_date']') OVERLAPS (check_in_date, check_out_date)) and b.room_id 
= r.room_id limit 1) is null GROUP BY city, province, country;

/*See hotels*/
SELECT h.hotel_id, c.chain_name, h.category, h.email, h.street_number, 
                        h.street_name, h.unit, h.city, h.province, h.country, h.zip FROM public.Hotel h 
                        INNER JOIN HotelChain c on h.chain_id = c.chain_id order by c.chain_name;

/*See capacities of rooms in a hotel*/
 SELECT * FROM public.roomcapacity where hotel_id=['id'] order by room_id;


 
/*--------- Queries for Employee -------*/

/*Log in*/
SELECT exists(Select * FROM public.Employee where SSN=['username'] and password='['password']');
   
/*See your roles*/
SELECT * FROM public.employeeroles where ssn=['user_id'] order by role_id
               

/*Add a booking*/
insert into public.BookingRental(reservation_date, check_in_date, check_out_date, checked_in, paid, room_id, customer_ssn, employee_ssn) values(
                now(), now(), '['check_out_date']', ['checked_in'],
                ['paid'], ['room_id'], ['customer_ssn'], ['employee_ssn']);

/*Check in a customer*/
update public.BookingRental set checked_in=true, employee_ssn=['user_id'] where booking_id= ['id'];

/*Confirm customer payment*/
update public.BookingRental set paid=true where booking_id=['id'];

/*View amenities for a room*/
SELECT * FROM public.Amenity where room_id=['id'] order by room_id;

/*View bookings for a customer*/
SELECT * FROM public.bookinginfo where hotel_id=(select hotel_id from employee where SSN=['user_id'] ); 
and customer_ssn=['ssn']  order by booking_id;

/*View the rooms of a hotel*/
SELECT * FROM public.Room where hotel_id=(select hotel_id from employee where SSN=['user_id']) order by room_id;
                   

/*--------- Queries for Manager -------*/

/*Login*/
SELECT exists(Select * FROM public.Employee where SSN=['username'] and password='['password']') and exists(Select * FROM public.Manages where SSN=['username']);
         

/*Add a booking*/
insert into public.BookingRental(reservation_date, check_in_date, check_out_date, checked_in, paid, room_id, customer_ssn, employee_ssn) values(
 '['reservation_date']', '['check_in_date']', '['check_out_date']', ['checked_in'],
['paid'], ['room_id'], ['customer_ssn'], ['employee_ssn']);

/*Delete a booking*/
delete from public.BookingRental where booking_id=['delete_id'];

/*Update a booking*/
update public.BookingRental set reservation_date='['reservation_date']', check_in_date='['check_in_date']',
        check_out_date='['check_out_date']',  checked_in=['checked_in'],  paid=['paid'], employee_ssn=['employee_ssn']
        where booking_id= ['booking_id'];

/*View bookings*/
SELECT * FROM public.bookinginfo order by booking_id;

/*Add a customer*/
insert into public.Customer(SSN, name, street_number, street_name, unit, city, province, country, zip, password) values(
['ssn'] , '['name']', ['streetnumber'], '['streetname']', '['unit']', '['city']',
'['province']', '['country']', '['zip']',
'['password']');

/*Delete a customer*/
delete from public.Customer where SSN=['id'];

/*Update a customer*/
update public.Customer set name='['name']', street_number=['streetnumber'],
street_name='['streetname']',  unit='['unit']',  city='['city']',
province='['province']',   country='['country']',  zip='['zip']',
password='['password']' where SSN=['ssn'];
        
/*View customers*/
SELECT * FROM public.Customer order by SSN;

/*Add an employee*/
insert into public.Employee(SSN, name, hotel_id, street_number, street_name, unit, city, province, country, zip, password) values(
['ssn'] , '['name']', ['hotel_id'] ,['streetnumber'] , '['streetname']', '['unit']', '['city']',
'['province']', '['country']', '['zip']',
'['password']');

/*Delete an employee*/
delete from public.Employee where SSN=['id'];

/*Update an employee*/
update public.Employee set name='['name']', hotel_id=['hotel_id'],
street_number=['streetnumber'],
street_name='['streetname']',  unit='['unit']',  city='['city']',
province='['province']',   country='['country']',  zip='['zip']',
password='['password']' where SSN=['ssn'];
        
/*View employees*/
SELECT * FROM public.Employee order by SSN;

/*Make an employee a manager*/
Insert into public.Manages(ssn, hotel_id) values(['ssn'], (select hotel_id from public.Employee where ssn=['ssn']));

/*Remove manager status for an employee*/
Delete from public.Manages where ssn=['ssn'];
                    
/*Check if employee is a manager*/
Select * FROM public.Manages where ssn=['ssn'];

/*Add a role to an employee*/
With A as (insert into public.role(name, description) values('[name]', '[description]') returning role_id)
insert into public.employeerole(employee_ssn, role_id) values('[ssn]', (select role_id from A));

/*Update a role*/
update public.Role set name='['name']', description='['description']'
where role_id=['role_id'];

/*Remove a role from an employee*/
delete from public.employeerole where role_id=['delete_id'];

/*View employee roles*/
SELECT * FROM public.employeeroles where ssn=['id'] order by role_id;


/*Add an amenity*/
insert into public.Amenity(room_id, name, description) values(
['room_id'], '['name']', '['description']' );
        
/*Edit an amenity*/
update public.Amenity set description='['description']'
where room_id=['room_id'] and name='['name']';

/*Delete an amenity*/ 
delete from public.Amenity where room_id=['delete_id'] and name='['name']';

/*View amenities for a room*/
SELECT * FROM public.Amenity where room_id=['id'] order by room_id;

/*Add a room*/
insert into public.Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) values(
['room_number'], ['hotel_id'], ['price'], ['capacity'], 
['sea_view'], ['mountain_view'], ['damages'], ['can_be_extended'] );

/*Update a room*/
update public.Room set room_number='['room_number']', price='['price']',
capacity=['capacity'],
sea_view=['sea_view'],  mountain_view=['mountain_view'],
damages=['damages'],   can_be_extended=['can_be_extended']
where room_id=['room_id'];

/*Delete a room*/
delete from public.Room where room_id=['delete_id'];

/*View rooms of a hotel*/
SELECT * FROM public.Room where hotel_id=['id'] order by room_id;

/*Add a phone number to a hotel*/
insert into public.HotelPhoneNumber(hotel_id, phone_number) values(
['hotel_id'], '['phone_number']');

/*Update a phone number*/
update public.HotelPhoneNumber set phone_number='['phone_number']'
where hotel_id=['hotel_id'] and phone_number='['prev_number']';

/*Delete a phone number*/
delete from public.HotelPhoneNumber where hotel_id=['hotel_id'] and phone_number='['number']';

/*View phone numbers for a hotel*/
SELECT * FROM public.HotelPhoneNumber where hotel_id=['id'] order by hotel_id;

/*Add a hotel*/
insert into public.Hotel(chain_id, category, email, street_number, street_name, unit, city, province, country, zip) values(
['chain_id'], ['category'], '['email']',  ['streetnumber'], '['streetname']', '['unit']', '['city']',
'['province']', '['country']', '['zip']');

/*Update a hotel*/
update public.Hotel set category=['category'], email='['email']',
street_number=['streetnumber'],
street_name='['streetname']',  unit='['unit']',  city='['city']',
province='['province']',   country='['country']',  zip='['zip']'
where hotel_id=['hotel_id'];

/*Delete a hotel*/
delete from public.Hotel where hotel_id=['delete_id'];

/*View hotels*/
SELECT * FROM public.Hotel where chain_id=['id'] order by hotel_id

/*Add hotel chain*/
insert into public.HotelChain(chain_name, email, street_number, street_name, unit, city, province, country, zip) values(
'['chain_name']', '['email']',  ['streetnumber'], '['streetname']', '['unit']', '['city']',
'['province']', '['country']', '['zip']');


/*Update hotel chain*/
update public.HotelChain set chain_name='['chain_name']', email='['email']',
street_number=['streetnumber'],
street_name='['streetname']',  unit='['unit']',  city='['city']',
province='['province']',   country='['country']',  zip='['zip']'
where chain_id=['chain_id'];

/*Delete hotel chain*/
delete from public.HotelChain where chain_id=['delete_id'];

/*View hotel chains*/
SELECT * FROM public.HotelChain order by chain_id;

/*Add hotel chain phone*/
insert into public.ChainPhoneNumber(chain_id, phone_number) values(
['chain_id'], '['phone_number']');

/*Update hotel chain phone*/
update public.ChainPhoneNumber set phone_number='['phone_number']'
where chain_id=['chain_id'] and phone_number='['prev_number']';


/*Delete hotel chain phone*/
delete from public.ChainPhoneNumber where chain_id=['chain_id'] and phone_number='['number']';

/*View hotel chain phones*/
SELECT * FROM public.ChainPhoneNumber where chain_id=['id'] order by chain_id;
                        