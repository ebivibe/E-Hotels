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
                        <input type="number" class="form-control" name="capacity" placeholder="Room Capacity">
                    </div>
                    <div class="form-group">
                        <input type="number" class="form-control" name="category" placeholder="Min Category (1-5)">
                    </div>
                </div>
                <div class="row">
                    <div class="form-group">
                        <input type="text" class="form-control" name="city" placeholder="City">
                    </div>
                    <div class="form-group">
                        <input type="text" class="form-control" name="chain_name" placeholder="Chain Name">
                    </div>
                </div>
                <div class="row">
                    <div class="form-group">
                        <input type="number" class="form-control" name="num_rooms" placeholder="#Rooms in Hotel">
                    </div>
                    <div class="form-group">
                        <input type="number" class="form-control" name="price" placeholder="Maximum Price">
                    </div>
                </div>
                <button type="submit" class="btn btn-outline-success" value="Submit">Find Rooms</button>
                </div>
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
                    <th scope="col">#Rooms in Hotel</th>
                    <th scope="col"> </th>
                </tr>
            </thead>
            <tbody>';





                $query = 'Select room_id, room_number, chain_name, street_number, street_name, unit,
                city, province, country, zip, capacity, price, category, num_rooms from roominfo r where damages=false';

                if(strlen($_POST["capacity"])>0){
                    $query .= ' and capacity ='.$_POST["capacity"];
                }
                if(strlen($_POST["category"])>0){
                    $query .= ' and category >='.$_POST["category"];
                }
                
                if(strlen($_POST["city"])>0){
                    $query .= ' and city ILIKE \'%'.$_POST["city"].'%\'';
                }

                
                if(strlen($_POST["chain_name"])>0){
                    $query .= ' and chain_name ILIKE \'%'.$_POST["chain_name"].'%\'';
                }

                if(strlen($_POST["num_rooms"])>0){
                    $query .= ' and num_rooms ='.$_POST["num_rooms"];
                }
                if(strlen($_POST["price"])>0){
                    $query .= ' and price <='.$_POST["price"];
                }
                $query .=' and (select b.room_id from BookingRental b where (SELECT (TIMESTAMP \''.$_POST["start_date"].'\', TIMESTAMP \''.$_POST["end_date"].'\')
                                                              OVERLAPS (check_in_date, check_out_date)) and b.room_id = r.room_id limit 1) is null';
                
                $result = pg_query($query) or die('Query failed: ' . pg_last_error());

                while ($line = pg_fetch_array($result, null, PGSQL_ASSOC)) {
                    echo "\t<tr scope=\"row\">\n";
                    echo "\t\t<td>" . $line["room_number"] . "</td>\n";
                    echo "\t\t<td>" . $line["chain_name"] . "</td>\n";
                    echo "\t\t<td>" . $line["unit"] . " " . $line["street_number"] . " " . $line["street_name"] . " " . $line["street_number"] . " 
                    , " . $line["city"] . ", " . $line["province"] . ", " . $line["country"] . " 
                    " . $line["zip"] . "</td>\n";
                    echo "\t\t<td>" . $line["capacity"] . "</td>\n";
                    echo "\t\t<td>" . $line["price"] . "</td>\n";
                    echo "\t\t<td>" . $line["category"] . "</td>\n";
                    echo "\t\t<td>" . $line["num_rooms"] . "</td>\n";
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