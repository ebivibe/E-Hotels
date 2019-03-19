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
<center class="customers">
  <h1> Hotels </h1>
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


<?php

if ( ! empty( $_POST ) ) {
  if ( isset( $_POST["id"] ) ) { 
    echo 
    '<th scope="col">
    <form action="hotel_add.php" method="post">
    <input type="hidden" name="id2" value="'.$_POST["id"].'"/>
    <input class="btn btn-primary" type="submit" name="submit-btn" value="Add" />
    </form>
    </th>
    </tr>
    </thead>
    <tbody>';

$query = 'SELECT * FROM public.Hotel where chain_id='.$_POST["id"].'order by hotel_id';
$result = pg_query($query) or die('Query failed: ' . pg_last_error());

while ($line = pg_fetch_array($result, null, PGSQL_ASSOC)) {
    echo "\t<tr scope=\"row\">\n";
    foreach ($line as $key => $col_value) {
        echo "\t\t<td>$col_value</td>\n";
    }
    echo"<td>
    <form action=\"hotel_edit.php\" method=\"post\">
    <input type=\"hidden\" name=\"id\" value=\"".$line["hotel_id"]."\"/>
    <input class=\"btn btn-primary\" type=\"submit\" name=\"submit-btn\" value=\"Edit\" />
    </form></td>";
    echo "\t</tr>\n";
  }
  }
}

?>
  </tbody>
</table>
</center>


</body>
</html>