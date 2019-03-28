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
        <h1> Hotels </h1>
        <table class="table" style="margin-top:10px;">
            <thead>
                <tr>
                    <th scope="col">Chain Name</th>
                    <th scope="col">Category</th>
                    <th scope="col">Email</th>
                    <th scope="col">Address</th>
                    <th scope="col"></th>


                    <?php

                        $query = 'SELECT h.hotel_id, c.chain_name, h.category, h.email, h.street_number, 
                        h.street_name, h.unit, h.city, h.province, h.country, h.zip FROM public.Hotel h 
                        INNER JOIN HotelChain c on h.chain_id = c.chain_id order by c.chain_name';
                        $result = pg_query($query) or die('Query failed: ' . pg_last_error());

                        while ($line = pg_fetch_array($result, null, PGSQL_ASSOC)) {
                            echo "\t<tr scope=\"row\">\n";
                            echo "\t\t<td>" . $line["chain_name"] . "</td>\n";
                            echo "\t\t<td>" . $line["category"] . "</td>\n";
                            echo "\t\t<td>" . $line["email"] . "</td>\n";
                            echo "\t\t<td>" . $line["unit"] . " " . $line["street_number"] . " " . $line["street_name"] . " " . $line["street_number"] . " 
                            , " . $line["city"] . ", " . $line["province"] . ", " . $line["country"] . " 
                            " . $line["zip"] . "</td>\n";
                            echo "<td>
                            <div class=\"dropdown\">
                            <button class=\"btn btn-outline-success dropdown-toggle\" type=\"button\" id=\"dropdownMenuButton\" data-toggle=\"dropdown\" aria-haspopup=\"true\" aria-expanded=\"false\">
                              Options
                            </button>
                            <div class=\"dropdown-menu dropdown-menu-right\" aria-labelledby=\"dropdownMenuButton\">
                            <form action=\"view_capacities.php\" method=\"post\">
                            <input type=\"hidden\" name=\"id\" value=\"" . $line["hotel_id"] . "\"/>
                            <input class=\"dropdown-item\" type=\"submit\" name=\"submit-btn\" value=\"See capacities\" />
                            </form>";
          
                              echo "</div></div></td>";
                              echo "\t</tr>\n";
                        }

                    ?>
                    </tbody>
        </table>
    </center>
</body>

</html> 