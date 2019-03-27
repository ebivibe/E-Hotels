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
                    <th scope="col">Room Number</th>
                    <th scope="col">Chain Name</th>
                    <th scope="col">Hotel Address</th>
                    <th scope="col">Customer SSN</th>
                    <th scope="col">Employee SSN</th>
                    <th scope="col"> </th>
                </tr>
            </thead>
            <tbody>


                <?php


                $query = 'SELECT * FROM public.bookinginfo order by booking_id';
                $result = pg_query($query) or die('Query failed: ' . pg_last_error());

                while ($line = pg_fetch_array($result, null, PGSQL_ASSOC)) {
                    echo "\t<tr scope=\"row\">\n";
                    echo "\t\t<td>".$line["booking_id"]."</td>\n";
                    echo "\t\t<td>".date('Y-m-d', strtotime($line["reservation_date"]))."</td>\n";
                    echo "\t\t<td>".date('Y-m-d', strtotime($line["check_in_date"]))."</td>\n";
                    echo "\t\t<td>".date('Y-m-d', strtotime($line["check_out_date"]))."</td>\n";
                    echo "\t\t<td>".$line["checked_in"]."</td>\n";
                    echo "\t\t<td>".$line["paid"]."</td>\n";
                    echo "\t\t<td>".$line["room_number"]."</td>\n";
                    echo "\t\t<td>".$line["chain_name"]."</td>\n";
                    echo "\t\t<td>".$line["unit"]." ".$line["street_number"]." ".$line["street_name"]." ".$line["street_number"]." 
                    , ".$line["city"].", ".$line["province"].", ".$line["country"]." 
                    ".$line["zip"]."</td>\n"; 
                    echo "\t\t<td>".$line["customer_ssn"]."</td>\n";
                    echo "\t\t<td>".$line["employee_ssn"]."</td>\n";
                    echo "<td>
                  <div class=\"dropdown\">
                  <button class=\"btn btn-outline-success dropdown-toggle\" type=\"button\" id=\"dropdownMenuButton\" data-toggle=\"dropdown\" aria-haspopup=\"true\" aria-expanded=\"false\">
                    Options
                  </button>
                  <div class=\"dropdown-menu\" aria-labelledby=\"dropdownMenuButton\">
                  <form action=\"booking/booking_edit.php\" method=\"post\">
                  <input type=\"hidden\" name=\"id\" value=\"" . $line["booking_id"] . "\"/>
                  <input class=\"dropdown-item\" type=\"submit\" name=\"submit-btn\" value=\"Edit\" />
                  </form>
                  <form action=\"booking/booking_delete.php\" method=\"post\">
                    <input type=\"hidden\" name=\"delete_id\" value=\"" . $line["booking_id"] . "\"/>
                    <input class=\"dropdown-item\" type=\"submit\" name=\"submit-btn\" value=\"Delete Booking\" />
                  </form>
                  </div>
                  </div>
                  
              
                  </td>";
                    echo "\t</tr>\n";
                }


                ?>


            </tbody>
        </table>
    </center>


</body>

</html> 