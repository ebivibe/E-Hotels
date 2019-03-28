the dates (start, end) of booking or renting, the room capacity, the area, the hotel chain, the
category of the hotel, the total number of rooms in the hotel, the price of the rooms. 


Select room_id, room_number, chain_name, hotel_id, street_number, street_name, unit,
 city, province, country
 from roominfo r where damages=false and capacity = CAPACITY and city ILIKE '%AREA%'
 and chain_name ILIKE '%CHAIN%' and category >=  CATEGORY and num_rooms = NUMBEROFROOMSWHY and price <= price and  
(select b.room_id from BookingRental b where (SELECT (TIMESTAMP '2019-07-05', TIMESTAMP '2019-07-07')
											  OVERLAPS (check_in_date, check_out_date)) and b.room_id = r.room_id limit 1) is null ;



Select room_id, room_number, chain_name, street_number, street_name, unit, city, province, country, 
zip, capacity, price, category, num_rooms from roominfo r where damages=false and  
(select b.room_id from BookingRental b where (SELECT (TIMESTAMP '2019-07-05', TIMESTAMP '2019-07-07')
											  OVERLAPS (check_in_date, check_out_date)) and b.room_id = r.room_id limit 1) is null ;



Select COUNT(room_id), city, province, country
 from roominfo r where damages=false and  
(select b.room_id from BookingRental b where (SELECT (TIMESTAMP '2040-07-05', TIMESTAMP '2040-07-07')
OVERLAPS (check_in_date, check_out_date)) and b.room_id = r.room_id limit 1) is null GROUP BY city, province, country ;

