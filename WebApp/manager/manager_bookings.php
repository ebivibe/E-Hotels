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
    include("manager_nav.php")
    ?>


    <center class="customers">
        <h1>Bookings</h1>
        <table class="table" style="margin-top:10px;">
            <thead>
                <tr>
                    <th scope="col">Booking ID</th>
                    <th scope="col">Reservation Date</th>
                    <th scope="col">Checked In Date</th>
                    <th scope="col">Checked Out Date</th>
                    <th scope="col">Checked In</th>
                    <th scope="col">Paid</th>
                    <th scope="col">Room ID</th>
                    <th scope="col">Customer SSN</th>
                    <th scope="col">Employee SSN</th>
                    <th scope="col"> <a class="btn btn-primary" href="bookings/bookings_add.php" role="button">Add Booking</a></th>
             
                </tr>
            </thead>
            <tbody>


                <?php


                $query = 'SELECT * FROM public.BookingRental order by booking_id';
                $result = pg_query($query) or die('Query failed: ' . pg_last_error());

                while ($line = pg_fetch_array($result, null, PGSQL_ASSOC)) {
                  echo "\t<tr scope=\"row\">\n";
                  foreach ($line as $key => $col_value) {
                    echo "\t\t<td>$col_value</td>\n";
                  }
                  echo "<td><form action=\"booking/booking_edit.php\" method=\"post\"><input type=\"hidden\" name=\"id\" value=\"" . $line["booking_id"] . "\"/><input class=\"btn btn-primary\" type=\"submit\" name=\"submit-btn\" value=\"Edit\" /></form></td>";
                  echo "\t</tr>\n";
                }


                ?>


            </tbody>
        </table>
    </center>


</body>

</html> 