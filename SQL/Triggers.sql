CREATE TRIGGER add_archive 
    REFERENCING NEW ROW AS nrow
    AFTER INSERT ON BookingRental 
    BEGIN ATOMIC
        INSERT INTO Archive 
            SELECT R.room_number, 
                H.street_number as hotel_street_number,
                H.street_name as hotel_street_name,
                H.unit as hotel_unit,
                H.city as hotel_city,
                H.province as hotel_province,
                H.country as hotel_country,
                H.zip as hotel_zip,
                B.check_in_date,
                HC.chain_name as hotel_chain,
                B.reservation_date,
                B.check_out_date,
                B.checked_in,
                B.customer_ssn,
                B.employee_ssn
            FROM Room R, 
                Hotel H, 
                HotelChain HC, 
                BookingRental B
            WHERE nrow.booking_id = B.booking_id AND
                B.room_id = R.room_id AND
                R.hotel_id = H.hotel_id AND
                H.chain_id = HC.chain_id
    END;