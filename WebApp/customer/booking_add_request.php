<?php
require_once("../helpers/login_check.php");
?>


<!DOCTYPE html>
<html>

<head>
    <?php

    include("../helpers/imports.php");
    include("../helpers/common.php");
    ?>
</head>

<body>
<?php
    if (!empty($_POST)) {
        if (isset($_POST["room_id"])) {
            $query = 'insert into public.BookingRental(reservation_date, check_in_date, check_out_date, checked_in, paid, room_id, customer_ssn, employee_ssn) values(
                now(), \'' . $_POST['check_in_date'] . '\',\'' . $_POST['check_out_date'] . '\', false,
                false , ' . $_POST['room_id'] . ', '.$_SESSION['user_id'].', null )';
            $result = pg_query($query);
            print_r($query);

        if (!$result) {
            $_SESSION['message'] = "Booking failed: ". $query;
          header("Location: view_bookings.php");
        } else {
            $_SESSION['message'] = "Booking Successful";
          header("Location: view_bookings.php");
        }
        }
    }


    ?>

</body>

</html> 