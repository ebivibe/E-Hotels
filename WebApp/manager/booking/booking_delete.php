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
          if (isset($_POST["delete_id"])) {
            $query = 'delete from public.BookingRental where booking_id=' . $_POST["delete_id"];
            $result = pg_query($query);
            print_r($query);

            if (!$result) {
              echo "<script>alert('Edit Failed');</script>";
              header("Location: ../manager_bookings.php");
            } else {
              echo "<script>alert('Edit Success');</script>";
              header("Location: ../manager_bookings.php");
            }
          }
        }

        ?>
</body>
</html>