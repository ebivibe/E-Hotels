<?php
require_once("../helpers/login_check.php");
?>

<!DOCTYPE html>
<html>
<head>
<?php
include("../helpers/imports.php");
?>
</head>
<body>
<?php
include("employee_nav.php")
?>

<center>
<h1 class="title">  Welcome Employee 
<?php
echo $_SESSION['user_id'];
?>
</h1>
<a class="btn btn-outline-success logoutbutton" href="../helpers/logout.php">Logout</a>
</center>


</body>
</html>