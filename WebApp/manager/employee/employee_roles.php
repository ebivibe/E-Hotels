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
        <h1> Roles </h1>
        <table class="table" style="margin-top:10px; margin-left: 50px; margin-right: 100px;">
            <thead>
                <tr>
                    <th scope="col">Role ID</th>
                    <th scope="col">Employee SSN</th>
                    <th scope="col">Name</th>
                    <th scope="col">Description</th>


                    <?php

                    if (!empty($_POST)) {
                        if (isset($_POST["id"])) {
                            echo
                                '<th scope="col">
    <form action="role/role_add.php" method="post">
    <input type="hidden" name="id" value="' . $_POST["id"] . '"/>
    <input class="btn btn-outline-success" type="submit" name="submit-btn" value="Add" />
    </form>
    </th>
    </tr>
    </thead>
    <tbody>';

                            $query = 'SELECT * FROM public.employeeroles where ssn=' . $_POST["id"] . 'order by role_id';
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
    <form action=\"role/role_edit.php\" method=\"post\">
    <input type=\"hidden\" name=\"id\" value=\"" . $line["role_id"] . "\"/>
    <input class=\"dropdown-item\" type=\"submit\" name=\"submit-btn\" value=\"Edit\" />
    </form>
    <form action=\"\" method=\"post\">
      <input type=\"hidden\" name=\"delete_id\" value=\"" . $line["role_id"] . "\"/>
      <input class=\"dropdown-item\" type=\"submit\" name=\"submit-btn\" value=\"Remove Role\" />
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

        <h1> Manager Status </h1>
        <?php
        $query = 'Select * FROM public.Manages where ssn=' . $_POST['id'];
        $result = pg_query($query);
        if (pg_num_rows($result) == 0) {
            echo "Not a manager";
        } else {
            $row = pg_fetch_row($result);
            echo "Manager for hotel with id: " . $row[1];
        }

        echo '<form action="role/manager_toggle.php" method="post">
        <input type="hidden" name="ssn" value="' . $_POST['id'] .'"/>
        <button type="submit" style="margin-top: 20px;" class="btn btn-outline-success" value="Submit">Toggle Manager Status</button>
        </form>';
        ?>
        
    </center>


    <?php


    if (!empty($_POST)) {
        if (isset($_POST["delete_id"])) {
            $query = 'delete from public.employeerole where role_id=' . $_POST["delete_id"];
            $result = pg_query($query);
            print_r($query);

            if (!$result) {
                echo "<script>alert('Edit Failed');</script>";
                header("Location: ../manager_employees.php");
            } else {
                echo "<script>alert('Edit Success');</script>";
                header("Location: ../manager_employees.php");
            }
        }
    }
    ?>


</body>

</html> 