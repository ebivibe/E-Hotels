
<!DOCTYPE html>
<html>
<head>
<?php
include("helpers/imports.php");

?>
</head>
<body>
  <?php
  session_start();
  if(isset($_SESSION['user_id'] )){
    unset($_SESSION['user_id']);
  }
  ?>


<center>
<h1 class="title">E Hotel</h1>
<div class="loginbuttons">
<a class="btn btn-primary loginbutton" href="employee/employee_login.php" role="button">Employee Login</a>
<a class="btn btn-primary loginbutton" href="customer/customer_login.php" role="button">Customer Login</a>
<a class="btn btn-primary" href="admin/admin_login.php" role="button">Admin Login</a>
</div>
</center>



<?php
/*
$dbconn2 = pg_connect("host=localhost port=5432 user=postgres password=Orange2349");

$query = 'SELECT * FROM lab.artist';
$result = pg_query($query) or die('Query failed: ' . pg_last_error());

echo "<table>\n";
while ($line = pg_fetch_array($result, null, PGSQL_ASSOC)) {
    echo "\t<tr>\n";
    foreach ($line as $key => $col_value) {
        echo "\t\t<td>$col_value</td>\n";
    }
    echo "\t</tr>\n";
}
echo "</table>\n";
*/
?>

</body>
</html>