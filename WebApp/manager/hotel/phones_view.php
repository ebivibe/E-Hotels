<?php
require_once("../../helpers/login_check.php");
?>

<!DOCTYPE html>
<html>

<head>
    <?php
    include("../../helpers/imports.php");
    include("../../helpers/common.php");
    ?>
</head>

<body>
<?php
    include("hotel_nav.php")
?>

<?php
    ?>
    <center class="customers">
        <h1> Phone Numbers</h1>
        <table class="table" style="margin-top:10px; margin-left: 50px; margin-right: 100px;">
            <thead>
                <tr>
                    <th scope="col">Hotel ID</th>
                    <th scope="col">Phone Number</th>


                    <?php

                    if (!empty($_POST)) {
                      if (isset($_POST["id"])) {
                        echo
                          '<th scope="col">
    <form action="phone_add.php" method="post">
    <input type="hidden" name="id" value="' . $_POST["id"] . '"/>
    <input class="btn btn-outline-success" type="submit" name="submit-btn" value="Add" />
    </form>
    </th>
    </tr>
    </thead>
    <tbody>';

                        $query = 'SELECT * FROM public.HotelPhoneNumber where hotel_id=' . $_POST["id"] . 'order by hotel_id';
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
    <form action=\"phone_edit.php\" method=\"post\">
    <input type=\"hidden\" name=\"id\" value=\"" . $line["hotel_id"] . "\"/>
    <input type=\"hidden\" name=\"number\" value=\"" . $line["phone_number"] . "\"/>
    <input class=\"dropdown-item\" type=\"submit\" name=\"submit-btn\" value=\"Edit\" />
    </form>
    <form action=\"\" method=\"post\">
      <input type=\"hidden\" name=\"hotel_id\" value=\"" . $line["hotel_id"] . "\"/>
      <input type=\"hidden\" name=\"number\" value=\"" . $line["phone_number"] . "\"/>
      <input class=\"dropdown-item\" type=\"submit\" name=\"submit-btn\" value=\"Delete Phone Number\" />
    </form>
    </div>
    </div>
    

    </td>";
                          echo "\t</tr>\n";
                        }
                      }
                    }

                    ?>
                    </tbody>
        </table>
    </center>
    <?php


    if (!empty($_POST)) {
      if (isset($_POST["hotel_id"])) {
        $query = 'delete from public.HotelPhoneNumber where hotel_id=' . $_POST["hotel_id"] . ' and phone_number=\'' . $_POST["number"].'\'';
        $result = pg_query($query);
        print_r($query);
       // exit;

        if (!$result) {
          echo "<script>alert('Edit Failed');</script>";
          header("Location: ../manager_chains.php");
        } else {
          echo "<script>alert('Edit Success');</script>";
          header("Location: ../manager_chains.php");
        }
      }
    }
    ?>


</body>

</html> 