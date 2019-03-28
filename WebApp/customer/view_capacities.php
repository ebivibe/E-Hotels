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
    include("customer_nav.php")
    ?>
    <center class="customers">
        <h1> Rooms </h1>
        <table class="table" style="margin-top:10px;">
            <thead>
                <tr>
                    <th scope="col">Room Number</th>
                    <th scope="col">Capacity</th>
                    <th scope="col">Can be extended</th>
                    <th scope="col"></th>


                    <?php

                    if (!empty($_POST)) {
                      if (isset($_POST["id"])) {
                        

                        $query = 'SELECT * FROM public.Room where hotel_id=' . $_POST["id"] . 'order by room_id';
                        $result = pg_query($query) or die('Query failed: ' . pg_last_error());

                        while ($line = pg_fetch_array($result, null, PGSQL_ASSOC)) {
                            echo "\t<tr scope=\"row\">\n";
                            echo "\t\t<td>" . $line["room_number"] . "</td>\n";
                            echo "\t\t<td>" . $line["capacity"] . "</td>\n";
                            echo "\t\t<td>" . $line["can_be_extended"] . "</td>\n";
                            echo "<td></td>";
                              echo "\t</tr>\n";
                        }
                      }
                    }

                    ?>
                    </tbody>
        </table>
    </center>
   


</body>

</html> 