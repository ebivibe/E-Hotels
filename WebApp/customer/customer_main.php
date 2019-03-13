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
include("customer_nav.php")
?>

<center>
<h1 class="title">  Welcome 
<?php
echo $_SESSION['user_id'] ;
?>
</h1>
<a class="btn btn-primary logoutbutton" href="../helpers/logout.php">Logout</a>
</center>


</body>
</html>