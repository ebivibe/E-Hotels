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
        <h1>Employees</h1>
        <table class="table" style="margin-top:10px;">
            <thead>
                <tr>
                    <th scope="col">SSN</th>
                    <th scope="col">Name</th>
                    <th scope="col">Hotel ID</th>
                    <th scope="col">Street #</th>
                    <th scope="col">Street Name</th>
                    <th scope="col">Unit </th>
                    <th scope="col">City </th>
                    <th scope="col">Province</th>
                    <th scope="col">Country</th>
                    <th scope="col">Zip</th>
                    <th scope="col">Password</th>
                    <th scope="col"> <a class="btn btn-primary" href="employee/employee_add.php" role="button">Add Employee</a></th>
             
                </tr>
            </thead>
            <tbody>


                <?php


                $query = 'SELECT * FROM public.Employee order by SSN';
                $result = pg_query($query) or die('Query failed: ' . pg_last_error());

                while ($line = pg_fetch_array($result, null, PGSQL_ASSOC)) {
                  echo "\t<tr scope=\"row\">\n";
                  foreach ($line as $key => $col_value) {
                    echo "\t\t<td>$col_value</td>\n";
                  }

                  echo "<td><div class=\"dropdown\">
                  <button class=\"btn btn-secondary dropdown-toggle\" type=\"button\" id=\"dropdownMenuButton\" data-toggle=\"dropdown\" aria-haspopup=\"true\" aria-expanded=\"false\">
                    Options
                  </button>
                  <div class=\"dropdown-menu\" aria-labelledby=\"dropdownMenuButton\">
                  <form action=\"employee/employee_edit.php\" method=\"post\">
                  <input type=\"hidden\" name=\"id\" value=\"" . $line["ssn"] . "\"/>
                  <input class=\"dropdown-item\" type=\"submit\" name=\"submit-btn\" value=\"Edit\" />
                  </form>
                  <form action=\"employee/employee_delete.php\" method=\"post\">
                  <input type=\"hidden\" name=\"id\" value=\"" . $line["ssn"] . "\"/>
                  <input class=\"dropdown-item\" type=\"submit\" name=\"submit-btn\" value=\"Delete\" />
                  </form>
                  <form action=\"employee/employee_roles.php\" method=\"post\">
                  <input type=\"hidden\" name=\"id\" value=\"" . $line["ssn"] . "\"/>
                  <input class=\"dropdown-item\" type=\"submit\" name=\"submit-btn\" value=\"View Roles\" />
                  </form>
                  </div><td>";
                  echo "\t</tr>\n";
                }


                ?>
            </tbody>
        </table>
    </center>


</body>

</html> 