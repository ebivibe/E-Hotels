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
        <h1> Roles </h1>
        <table class="table roles" style="margin-top:10px; margin-left: 50px; margin-right: 100px;">
            <thead>
                <tr>
                    <th scope="col">Name</th>
                    <th scope="col">Description</th>

                </tr>
                <?php


                $query = 'SELECT * FROM public.employeeroles where ssn=' . $_SESSION['user_id'] . 'order by role_id';
                $result = pg_query($query) or die('Query failed: ' . pg_last_error());

                while ($line = pg_fetch_array($result, null, PGSQL_ASSOC)) {
                    echo "\t<tr scope=\"row\">\n";
                    echo "\t\t<td>" . $line["name"] . "</td>\n";
                    echo "\t\t<td>" . $line["description"] . "</td>\n";
                    echo "\t</tr>\n";
                }

                ?>
                </tbody>
        </table>

        <h1> Manager Status </h1>
        <?php
        $query = 'Select * FROM public.Manages where ssn=' . $_SESSION['user_id'];
        $result = pg_query($query);
        if (pg_num_rows($result) == 0) {
            echo "Not a manager";
        } else {
            $row = pg_fetch_row($result);
            echo "Manager for hotel with id: " . $row[1];
        }
        ?>

    </center>


</body>

</html> 