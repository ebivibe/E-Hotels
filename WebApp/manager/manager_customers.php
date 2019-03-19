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
<a class="btn btn-primary" href="customer/customer_add.php" role="button">Add Customer</a>
<table class="table" style="margin-top:10px;">
  <thead>
    <tr>
      <th scope="col">SSN</th>
      <th scope="col">Name</th>
      <th scope="col">Street #</th>
      <th scope="col">Street Name</th>
      <th scope="col">Unit </th>
      <th scope="col">City </th>
      <th scope="col">Province</th>
      <th scope="col">Country</th>
      <th scope="col">Zip</th>
      <th scope="col">Registration Date</th>
      <th scope="col">Password</th>
      <th scope="col"></th>
    </tr>
  </thead>
  <tbody>


<?php


$query = 'SELECT * FROM public.Customer order by SSN';
$result = pg_query($query) or die('Query failed: ' . pg_last_error());

while ($line = pg_fetch_array($result, null, PGSQL_ASSOC)) {
    echo "\t<tr scope=\"row\">\n";
    foreach ($line as $key => $col_value) {
        echo "\t\t<td>$col_value</td>\n";
    }
    echo"<td><form action=\"customer/customer_edit.php\" method=\"post\"><input type=\"hidden\" name=\"id\" value=\"".$line["ssn"]."\"/><input class=\"btn btn-primary\" type=\"submit\" name=\"submit-btn\" value=\"Edit\" /></form></td>";
    echo "\t</tr>\n";
}


?>


  </tbody>
</table>
</center>


</body>
</html>