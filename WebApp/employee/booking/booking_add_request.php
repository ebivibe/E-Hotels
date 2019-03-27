<?php
require_once("../../helpers/login_check.php");
?>


<!DOCTYPE html>
<html>

<head>
    <?php

    include("../../helpers/imports.php");
    include("../../helpers/common.php");
    ?>
</head>

<body>
<?php
    if (!empty($_POST)) {
        if (isset($_POST["room_id"])) {
            $query = 'insert into public.BookingRental(reservation_date, check_in_date, check_out_date, checked_in, paid, room_id, customer_ssn, employee_ssn) values(
                now(), now(), \'' . $_POST['check_out_date'] . '\', \'' . $_POST['checked_in'] . '\',
                \'' . $_POST['paid'] . '\', ' . $_POST['room_id'] . ', ' . $_POST['customer_ssn'] . ', ' . $_POST['employee_ssn'] . ')';
            $result = pg_query($query);
            print_r($query);

        if (!$result) {
            $_SESSION['message'] = "Booking failed";
          header("Location: ../bookings_view.php");
        } else {
            $_SESSION['message'] = "Booking Successful";
          header("Location: ../bookings_view.php");
        }
        }
    }


    ?>

</body>

</html> 