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
    include("customer_nav.php");

    if(isset($_SESSION['message'])){
        echo '<div class="alert alert-warning alert-dismissible fade show" role="alert">'.$_SESSION['message'].'
        <button type="button" class="close" data-dismiss="alert" aria-label="Close">
        <span aria-hidden="true">&times;</span>
      </button>
        </div>';
        unset($_SESSION['message']);
    }
    ?>


    <center class="customers">
        <h1>Bookings</h1>
        <?php

                echo '<table class="table" style="margin-top:10px;">
            <thead>
                <tr>
                    <th scope="col">Reservation Date</th>
                    <th scope="col">Check In Date</th>
                    <th scope="col">Check Out Date</th>
                    <th scope="col">Checked In</th>
                    <th scope="col">Paid</th>
                    <th scope="col">Chain Name</th>
                    <th scope="col">Room Number</th>
                    <th scope="col">Hotel Address</th>
                </tr>
            </thead>
            <tbody>';





                $query = 'SELECT * FROM public.bookinginfo where customer_ssn='.$_SESSION['user_id'].'  order by booking_id';
                $result = pg_query($query) or die('Query failed: ' . pg_last_error());

                while ($line = pg_fetch_array($result, null, PGSQL_ASSOC)) {
                    echo "\t<tr scope=\"row\">\n";
                    echo "\t\t<td>" . date('Y-m-d', strtotime($line["reservation_date"])) . "</td>\n";
                    echo "\t\t<td>" . date('Y-m-d', strtotime($line["check_in_date"])) . "</td>\n";
                    echo "\t\t<td>" . date('Y-m-d', strtotime($line["check_out_date"])) . "</td>\n";
                    echo "\t\t<td>" . $line["checked_in"] . "</td>\n";
                    echo "\t\t<td>" . $line["paid"] . "</td>\n";
                    echo "\t\t<td>".$line["chain_name"]."</td>\n";
                    echo "\t\t<td>" . $line["room_number"] . "</td>\n";
                    echo "\t\t<td>".$line["unit"]." ".$line["street_number"]." ".$line["street_name"]." ".$line["street_number"]." 
                    , ".$line["city"].", ".$line["province"].", ".$line["country"]." 
                    ".$line["zip"]."</td>\n"; 
                    echo "\t</tr>\n";
                }


                echo '</tbody>
        </table>
    </center>';
        ?>

</body >

</html>