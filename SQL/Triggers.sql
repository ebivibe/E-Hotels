CREATE OR REPLACE FUNCTION archive_data() RETURNS TRIGGER AS $archive$
	BEGIN INSERT INTO Archive(room_number, street_number, street_name, unit, hotel_city, hotel_province, hotel_country, 
        hotel_zip, check_in_date, hotel_chain_name, reservation_date, check_out_date, customer_ssn, employee_ssn)
            SELECT R.room_number, 
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
                B.employee_ssn
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