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
    include("employee_nav.php");

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
        <form action="" method="post" class='loginform'>
            <div class="form-group">
                <input type="text" class="form-control" name="ssn" placeholder="Enter the customer SSN" required>
            </div>
            <button type="submit" class="btn btn-outline-success" value="Submit">Find Bookings</button>
        </form>

        <?php

        if (!empty($_POST)) {
            if (isset($_POST['ssn'])) {

                echo '<table class="table" style="margin-top:10px;">
            <thead>
                <tr>
                    <th scope="col">Booking ID</th>
                    <th scope="col">Reservation Date</th>
                    <th scope="col">Checked In Date</th>
                    <th scope="col">Checked Out Date</th>
                    <th scope="col">Checked In</th>
                    <th scope="col">Paid</th>
                    <th scope="col">Room Number</th>
                    <th scope="col">Customer SSN</th>
                    <th scope="col">Employee SSN</th>
                    <th scope="col"> </th>
                </tr>
            </thead>
            <tbody>';





                $query = 'SELECT * FROM public.bookinginfo where hotel_id=(select hotel_id from employee where SSN=' . $_SESSION['user_id'] . ') 
                            and customer_ssn='.$_POST["ssn"].'  order by booking_id';
                $result = pg_query($query) or die('Query failed: ' . pg_last_error());

                while ($line = pg_fetch_array($result, null, PGSQL_ASSOC)) {
                    echo "\t<tr scope=\"row\">\n";
                    echo "\t\t<td>" . $line["booking_id"] . "</td>\n";
                    echo "\t\t<td>" . date('Y-m-d', strtotime($line["reservation_date"])) . "</td>\n";
                    echo "\t\t<td>" . date('Y-m-d', strtotime($line["check_in_date"])) . "</td>\n";
                    echo "\t\t<td>" . date('Y-m-d', strtotime($line["check_out_date"])) . "</td>\n";
                    echo "\t\t<td>" . $line["checked_in"] . "</td>\n";
                    echo "\t\t<td>" . $line["paid"] . "</td>\n";
                    echo "\t\t<td>" . $line["room_number"] . "</td>\n";
                    echo "\t\t<td>" . $line["customer_ssn"] . "</td>\n";
                    echo "\t\t<td>" . $line["employee_ssn"] . "</td>\n";
                    echo "<td>
                  <div class=\"dropdown\">
                  <button class=\"btn btn-outline-success dropdown-toggle\" type=\"button\" id=\"dropdownMenuButton\" data-toggle=\"dropdown\" aria-haspopup=\"true\" aria-expanded=\"false\">
                    Options
                  </button>
                  <div class=\"dropdown-menu dropdown-menu-right\" aria-labelledby=\"dropdownMenuButton\">";
                    if ($line[checked_in] === "f") {
                        echo "<form action=\"booking/booking_check_in.php\" method=\"post\">
                  <input type=\"hidden\" name=\"id\" value=\"" . $line["booking_id"] . "\"/>
                  <input class=\"dropdown-item\" type=\"submit\" name=\"submit-btn\" value=\"Check In Customer\" />
                  </form>";
                    }
                    if ($line[paid] === "f") {
                        echo "<form action=\"booking/booking_pay.php\" method=\"post\">
                    <input type=\"hidden\" name=\"id\" value=\"" . $line["booking_id"] . "\"/>
                    <input class=\"dropdown-item\" type=\"submit\" name=\"submit-btn\" value=\"Confirm Payment\" />
                  </form>";
                    }
                    if ($line[paid] === "t" && $line[checked_in] === "t") {
                        echo '<div class="dropdown-item disabled"> Booking Complete</div>';
                    }

                    echo "</div></div></td>";
                    echo "\t</tr>\n";
                }


                echo '</tbody>
        </table>
    </center>';
            }
        }
        ?>

</body >

</html>