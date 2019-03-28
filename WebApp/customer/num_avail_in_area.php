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

    if (isset($_SESSION['message'])) {
        echo '<div class="alert alert-warning alert-dismissible fade show" role="alert">' . $_SESSION['message'] . '
        <button type="button" class="close" data-dismiss="alert" aria-label="Close">
        <span aria-hidden="true">&times;</span>
      </button>
        </div>';
        unset($_SESSION['message']);
    }
    ?>


    <center class="customers">
        <h1>Enter Dates</h1>
        <form action="" method="post" class='loginform'>
            <div class="container">
                <div class="row">
                    <div class="form-group date">
                        <input type="date" class="form-control" name="start_date" placeholder="Start Date" required>
                    </div>
                    <div class="form-group">
                        <input type="date" class="form-control" name="end_date" placeholder="End Date" required>
                    </div>
                </div>
                
                <button type="submit" class="btn btn-outline-success" value="Submit">Find # Rooms Per Area</button>

        </form>
        </div>

        <?php

        if (!empty($_POST)) {
            if (isset($_POST['start_date']) && isset($_POST['end_date'])) {

                echo '<table class="table" style="margin-top:10px;">
            <thead>
                <tr>
                    <th scope="col">Number of Rooms</th>
                    <th scope="col">City</th>
                    <th scope="col">Province</th>
                    <th scope="col">Country</th>
                    <th scope="col"> </th>
                </tr>
            </thead>
            <tbody>';





                $query = 'Select COUNT(room_id) as num, city, province, country 
                from roominfo r where damages=false and 
                (select b.room_id from BookingRental b where (SELECT (TIMESTAMP \''.$_POST["start_date"].'\', 
                TIMESTAMP \''.$_POST["end_date"].'\') OVERLAPS (check_in_date, check_out_date)) and b.room_id 
                = r.room_id limit 1) is null GROUP BY city, province, country';
                $result = pg_query($query) or die('Query failed: ' . pg_last_error());

                while ($line = pg_fetch_array($result, null, PGSQL_ASSOC)) {
                    echo "\t<tr scope=\"row\">\n";
                    echo "\t\t<td>" . $line["num"] . "</td>\n";
                    echo "\t\t<td>" . $line["city"] . "</td>\n";
                    echo "\t\t<td>" . $line["province"] . "</td>\n";
                    echo "\t\t<td>" . $line["country"] . "</td>\n";
                    echo "<td>";
                    echo "</div></div></td>";
                    echo "\t</tr>\n";
                }


                echo '</tbody>
        </table>
    </center>';
            }
        }
        ?>

</body>

</html> 