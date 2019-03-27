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
      if (isset($_POST["id"])) {
        $query = 'update public.BookingRental set paid=true where booking_id=' . $_POST['id'];
        print_r($query);
        $result = pg_query($query);
        print_r($result);

        //exit;

        if (!$result) {
            $_SESSION['message'] = "Edit failed";
          header("Location: ../bookings_view.php");
        } else {
            $_SESSION['message'] = "Edit Successful";
          header("Location: ../bookings_view.php");
        }
      }
    }


    ?>
</body>

</html> 