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
        <h1> Hotels </h1>
        <table class="table" style="margin-top:10px;">
            <thead>
                <tr>
                    <th scope="col">Chain ID</th>
                    <th scope="col">Name</th>
                    <th scope="col">Category</th>
                    <th scope="col"># Hotels</th>
                    <th scope="col">Email</th>
                    <th scope="col">Street #</th>
                    <th scope="col">Street Name</th>
                    <th scope="col">Unit </th>
                    <th scope="col">City </th>
                    <th scope="col">Province</th>
                    <th scope="col">Country</th>
                    <th scope="col">Zip</th>


                    <?php

                    if (!empty($_POST)) {
                      if (isset($_POST["id"])) {
                        echo
                          '<th scope="col">
    <form action="hotel_add.php" method="post">
    <input type="hidden" name="id" value="' . $_POST["id"] . '"/>
    <input class="btn btn-outline-success" type="submit" name="submit-btn" value="Add" />
    </form>
    </th>
    </tr>
    </thead>
    <tbody>';

                        $query = 'SELECT * FROM public.Hotel where chain_id=' . $_POST["id"] . 'order by hotel_id';
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
    <form action=\"hotel_edit.php\" method=\"post\">
    <input type=\"hidden\" name=\"id\" value=\"" . $line["hotel_id"] . "\"/>
    <input class=\"dropdown-item\" type=\"submit\" name=\"submit-btn\" value=\"Edit\" />
    </form>
    <form action=\"rooms_view.php\" method=\"post\">
    <input type=\"hidden\" name=\"id\" value=\"" . $line["hotel_id"] . "\"/>
    <input class=\"dropdown-item\" type=\"submit\" name=\"submit-btn\" value=\"View Rooms\" />
    </form>
    <form action=\"phones_view.php\" method=\"post\">
    <input type=\"hidden\" name=\"id\" value=\"" . $line["hotel_id"] . "\"/>
    <input class=\"dropdown-item\" type=\"submit\" name=\"submit-btn\" value=\"View Phones\" />
    </form>
    
    <form action=\"\" method=\"post\">
      <input type=\"hidden\" name=\"delete_id\" value=\"" . $line["hotel_id"] . "\"/>
      <input class=\"dropdown-item\" type=\"submit\" name=\"submit-btn\" value=\"Delete Hotel\" />
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
        $query = 'delete from public.Hotel where hotel_id=' . $_POST["delete_id"];
        $result = pg_query($query);
        print_r($query);

        if (!$result) {
          $_SESSION['message'] = "Edit failed";
          header("Location: ../manager_chains.php");
        } else {
          $_SESSION['message'] = "Edit Successful";
          header("Location: ../manager_chains.php");
        }
      }
    }
    ?>

</body>

</html> 