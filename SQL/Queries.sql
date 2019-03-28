the dates (start, end) of booking or renting, the room capacity, the area, the hotel chain, the
category of the hotel, the total number of rooms in the hotel, the price of the rooms. 


Select room_id, room_number, chain_name, hotel_id, street_number, street_name, unit,
 city, province, country
 from roominfo where damages=false and capacity = CAPACITY and city ILIKE '%AREA%'
 and chain_name ILIKE '%CHAIN%' and category >=  CATEGORY and num_rooms = NUMBEROFROOMSWHY and price <= price and 
 exists room_id in (select room_id from Booking where NOT (SELECT (TIMESTAMP 'STARTDATE', TIMESTAMP 'ENDDATE')
  OVERLAPS (check_in_date, check_out_date))));



Select room_id from roominfo where damages=false 

and capacity = CAPACITY
and city ILIKE '%AREA%'
and chain_name ILIKE '%CHAIN%'
and category >=  CATEGORY 
and num_rooms = NUMBEROFROOMSWHY
and price <= price
and exists room_id in (select room_id from Booking where NOT (SELECT (TIMESTAMP 'STARTDATE', TIMESTAMP 'ENDDATE') OVERLAPS
       (check_in_date, check_out_date))))


