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
    <center class="customers">
        <h1> Amenities </h1>
        <table class="table" style="margin-top:10px; margin-left: 50px; margin-right: 100px;">
            <thead>
                <tr>
                    <th scope="col">Room ID</th>
                    <th scope="col">Name</th>
                    <th scope="col">Description</th>


                    <?php

                    if (!empty($_POST)) {
                      if (isset($_POST["id"])) {
                        echo
                          '<th scope="col">
    <form action="amenity_add.php" method="post">
    <input type="hidden" name="id" value="' . $_POST["id"] . '"/>
    <input class="btn btn-primary" type="submit" name="submit-btn" value="Add" />
    </form>
    </th>
    </tr>
    </thead>
    <tbody>';

                        $query = 'SELECT * FROM public.Amenity where room_id=' . $_POST["id"] . 'order by room_id';
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
    <form action=\"amenity_edit.php\" method=\"post\">
    <input type=\"hidden\" name=\"id\" value=\"" . $line["room_id"] . "\"/>
    <input type=\"hidden\" name=\"name\" value=\"" . $line["name"] . "\"/>
    <input class=\"dropdown-item\" type=\"submit\" name=\"submit-btn\" value=\"Edit\" />
    <form action=\"\" method=\"post\">
      <input type=\"hidden\" name=\"delete_id\" value=\"" . $line["room_id"] . "\"/>
      <input type=\"hidden\" name=\"name\" value=\"" . $line["name"] . "\"/>
      <input class=\"dropdown-item\" type=\"submit\" name=\"submit-btn\" value=\"Delete Amenity\" />
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
      if (isset($_POST["delete_id"])) {
        $query = 'delete from public.Amenity where room_id=' . $_POST["delete_id"] . ' and name=' . $_POST["name"];
        $result = pg_query($query);
        print_r($query);

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