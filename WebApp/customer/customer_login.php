
<!DOCTYPE html>
<html>
<head>
<?php
include("../helpers/imports.php");
?>
</head>
<body>


<center>
<h1 class="title">E Hotel Customer Login</h1>


<form action="" method="post" class='loginform'>
  <div class="form-group">
    <input type="text" class="form-control" name="username" placeholder="Enter your username" required>
   </div>
  <div class="form-group">
    <input type="password" class="form-control" name="password" placeholder="Password" required>
  </div>
  <button type="submit" class="btn btn-primary" value="Submit">Submit</button>
</form>
</center>
<?php

session_start();
if(isset($_SESSION['user_id'] )){
  unset($_SESSION['user_id']);
}

if ( ! empty( $_POST ) ) {
    if ( isset( $_POST['username'] ) && isset( $_POST['password'] ) ) {
        
      $_SESSION['user_id'] = $_POST['username'];

      header("Location: customer_main.php");
    }
}
?>


</body>
</html>