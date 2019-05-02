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
      if (isset($_POST["booking_id"])) {
        $query = 'update public.BookingRental set reservation_date=\'' . $_POST['reservation_date'] . '\', check_in_date=\'' . $_POST['check_in_date'] . '\',
        check_out_date=\'' . $_POST['check_out_date'] . '\',  checked_in=\'' . $_POST['checked_in'] . '\',  paid=\'' . $_POST['paid'] . '\', employee_ssn='. $_POST['employee_ssn'].'
        where booking_id=' . $_POST['booking_id'];
        print_r($query);
        $result = pg_query($query);
        print_r($result);

        //exit;

        if (!$result) {
            $_SESSION['message'] = "Edit failed";
          header("Location: ../manager_bookings.php");
        } else {
            $_SESSION['message'] = "Edit Successful";
          header("Location: ../manager_bookings.php");
        }
      }
    }


    ?>
</body>

</html> 