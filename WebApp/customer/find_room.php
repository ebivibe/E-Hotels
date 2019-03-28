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
        <h1>Find a Room</h1>
        <form action="" method="post" class='loginform'>
            <div class="container">
                <div class="row">
                    <div class="form-group">
                        <input type="text" class="form-control" name="start_date" placeholder="Start Date" required>
                    </div>
                    <div class="form-group">
                        <input type="text" class="form-control" name="end_date" placeholder="End Date" required>
                    </div>
                </div>
                <div class="row">
                    <div class="form-group">
                        <input type="number" class="form-control" name="capacity" placeholder="Room Capacity" required>
                    </div>
                    <div class="form-group">
                        <input type="number" class="form-control" name="capacity" placeholder="Minimum Category (1-5)" required>
                    </div>
                </div>
                <div class="row">
                    <div class="form-group">
                        <input type="text" class="form-control" name="city" placeholder="City" required>
                    </div>
                    <div class="form-group">
                        <input type="text" class="form-control" name="chain_name" placeholder="Chain Name" required>
                    </div>
                </div>
                <div class="row">
                    <div class="form-group">
                        <input type="number" class="form-control" name="num_rooms" placeholder="Number of Rooms" required>
                    </div>
                    <div class="form-group">
                        <input type="number" class="form-control" name="price" placeholder="Maximum Price" required>
                    </div>
                </div>
                <button type="submit" class="btn btn-outline-success" value="Submit">Find Rooms</button>
        </form>

        <?php

        if (!empty($_POST)) {
            if (isset($_POST['start_date']) && isset($_POST['end_date'])) {

                echo '<table class="table" style="margin-top:10px;">
            <thead>
                <tr>
                    <th scope="col">Room Number</th>
                    <th scope="col">Chain Name</th>
                    <th scope="col">Hotel Address</th>
                    <th scope="col">Capacity</th>
                    <th scope="col">Price</th>
                    <th scope="col">Category</th>
                    <th scope="col">Number of Rooms in Hotel</th>
                    <th scope="col"> </th>
                </tr>
            </thead>
            <tbody>';





                $query = 'Select room_id, room_number, chain_name, hotel_id, street_number, street_name, unit,
                city, province, country from roominfo where damages=false';

                $result = pg_query($query) or die('Query failed: ' . pg_last_error());

                while ($line = pg_fetch_array($result, null, PGSQL_ASSOC)) {
                    echo "\t<tr scope=\"row\">\n";
                    echo "\t\t<td>" . $line["room_number"] . "</td>\n";
                    echo "\t\t<td>" . $line["chain_name"] . "</td>\n";
                    echo "\t\t<td>" . $line["paid"] . "</td>\n";
                    echo "\t\t<td>" . $line["capacity"] . "</td>\n";
                    echo "\t\t<td>" . $line["price"] . "</td>\n";
                    echo "\t\t<td>" . $line["category"] . "</td>\n";
                    echo "<td>
                  <div class=\"dropdown\">
                  <button class=\"btn btn-outline-success dropdown-toggle\" type=\"button\" id=\"dropdownMenuButton\" data-toggle=\"dropdown\" aria-haspopup=\"true\" aria-expanded=\"false\">
                    Options
                  </button>
                  <div class=\"dropdown-menu dropdown-menu-right\" aria-labelledby=\"dropdownMenuButton\">
                  <form action=\"book_room.php\" method=\"post\">
                  <input type=\"hidden\" name=\"id\" value=\"" . $line["room_id"] . "\"/>
                  <input class=\"dropdown-item\" type=\"submit\" name=\"submit-btn\" value=\"Book Room\" />
                  </form>";

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