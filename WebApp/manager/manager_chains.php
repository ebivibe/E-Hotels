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
        <h1>Hotel Chains</h1>
        <table class="table" style="margin-top:10px;">
            <thead>
                <tr>
                    <th scope="col">Chain ID</th>
                    <th scope="col">Name</th>
                    <th scope="col"># of Hotels</th>
                    <th scope="col">Email</th>
                    <th scope="col">Street #</th>
                    <th scope="col">Street Name</th>
                    <th scope="col">Unit </th>
                    <th scope="col">City </th>
                    <th scope="col">Province</th>
                    <th scope="col">Country</th>
                    <th scope="col">Zip</th>
                    <th scope="col"> <a class="btn btn-primary" href="hotelchain/hotelchain_add.php" role="button">Add Hotel Chain</a></th>
                </tr>
            </thead>
            <tbody>


                <?php


                $query = 'SELECT * FROM public.HotelChain order by chain_id';
                $result = pg_query($query) or die('Query failed: ' . pg_last_error());

                while ($line = pg_fetch_array($result, null, PGSQL_ASSOC)) {
                  echo "\t<tr scope=\"row\">\n";
                  foreach ($line as $key => $col_value) {
                    echo "\t\t<td>$col_value</td>\n";
                  }
                  echo "<td>
    <div class=\"dropdown\">
    <button class=\"btn btn-secondary dropdown-toggle\" type=\"button\" id=\"dropdownMenuButton\" data-toggle=\"dropdown\" aria-haspopup=\"true\" aria-expanded=\"false\">
      Options
    </button>
    <div class=\"dropdown-menu\" aria-labelledby=\"dropdownMenuButton\">
    <form action=\"hotelchain/hotelchain_edit.php\" method=\"post\">
    <input type=\"hidden\" name=\"id\" value=\"" . $line["chain_id"] . "\"/>
    <input class=\"dropdown-item\" type=\"submit\" name=\"submit-btn\" value=\"Edit\" />
    </form>
    <form action=\"hotel/hotels_view.php\" method=\"post\">
    <input type=\"hidden\" name=\"id\" value=\"" . $line["chain_id"] . "\"/>
    <input class=\"dropdown-item\" type=\"submit\" name=\"submit-btn\" value=\"View Hotels\" />
    </form>
    <form action=\"hotelchain/hotelchain_delete.php\" method=\"post\">
      <input type=\"hidden\" name=\"delete_id\" value=\"" . $line["chain_id"] . "\"/>
      <input class=\"dropdown-item\" type=\"submit\" name=\"submit-btn\" value=\"Delete Chain\" />
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