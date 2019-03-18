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
<a class="btn btn-primary" href="hotel/hotel_add.php" role="button">Add Hotel</a>
<table class="table" style="margin-top:10px;">
  <thead>
    <tr>
      <th scope="col">Chain ID</th>
      <th scope="col">Name</th>
      <th scope="col">Category</th>
      <th scope="col">Email</th>
      <th scope="col">Street #</th>
      <th scope="col">Street Name</th>
      <th scope="col">Unit </th>
      <th scope="col">City </th>
      <th scope="col">Province</th>
      <th scope="col">Country</th>
      <th scope="col">Zip</th>
    </tr>
  </thead>
  <tbody>


<?php


$query = 'SELECT * FROM public.Hotel order by hotel_id';
$result = pg_query($query) or die('Query failed: ' . pg_last_error());

while ($line = pg_fetch_array($result, null, PGSQL_ASSOC)) {
    echo "\t<tr scope=\"row\">\n";
    foreach ($line as $key => $col_value) {
        echo "\t\t<td>$col_value</td>\n";
    }
    echo"<td><form action=\"hotel/hotel_edit.php\" method=\"post\"><input type=\"hidden\" name=\"id\" value=\"".$line["hotel_id"]."\"/><input class=\"btn btn-primary\" type=\"submit\" name=\"submit-btn\" value=\"Edit\" /></form></td>";
    echo "\t</tr>\n";
}

?>
  </tbody>
</table>
</center>


</body>
</html>