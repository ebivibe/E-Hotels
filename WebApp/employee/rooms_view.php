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
    include("employee_nav.php")
    ?>
    <center class="customers">
        <h1> Rooms </h1>
        <table class="table" style="margin-top:10px;">
            <thead>
                <tr>
                    <th scope="col">Room ID</th>
                    <th scope="col">Room Number</th>
                    <th scope="col">Hotel Id</th>
                    <th scope="col">Price</th>
                    <th scope="col">Capacity</th>
                    <th scope="col">Sea View</th>
                    <th scope="col">Montain View </th>
                    <th scope="col">Damages </th>
                    <th scope="col">Can be extended</th>


                    <?php
                    echo '  <th scope="col"></th></tr></thead><tbody>';

                    $query = 'SELECT * FROM public.Room where hotel_id=(select hotel_id from employee where SSN=' . $_SESSION['user_id'] . ') order by room_id';
                    $result = pg_query($query) or die('Query failed: ' . pg_last_error());

                    while ($line = pg_fetch_array($result, null, PGSQL_ASSOC)) {
                      echo "\t<tr scope=\"row\">\n";
                      foreach ($line as $key => $col_value) {
                        echo "\t\t<td>$col_value</td>\n";
                      }
                      echo "<td>
    <div class=\"dropdown\">
    <button class=\"btn btn-outline-success dropdown-toggle\" type=\"button\" id=\"dropdownMenuButton\" data-toggle=\"dropdown\" aria-haspopup=\"true\" aria-expanded=\"false\">
      Options
    </button>
    <div class=\"dropdown-menu\" aria-labelledby=\"dropdownMenuButton\">
    <form action=\"amenities_view.php\" method=\"post\">
    <input type=\"hidden\" name=\"id\" value=\"" . $line["room_id"] . "\"/>
    <input class=\"dropdown-item\" type=\"submit\" name=\"submit-btn\" value=\"View Amenities\" />
    </form>
    <form action=\"booking/booking_add.php\" method=\"post\">
    <input type=\"hidden\" name=\"id\" value=\"" . $line["room_id"] . "\"/>
    <input class=\"dropdown-item\" type=\"submit\" name=\"submit-btn\" value=\"Make a Booking\" />
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