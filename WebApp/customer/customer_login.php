
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

session_start();
if(isset($_SESSION['message'])){
  echo '<div class="alert alert-warning alert-dismissible fade show" role="alert">'.$_SESSION['message'].'
  <button type="button" class="close" data-dismiss="alert" aria-label="Close">
  <span aria-hidden="true">&times;</span>
</button>
  </div>';
  unset($_SESSION['message']);
}
if(isset($_SESSION['user_id'] )){
  unset($_SESSION['user_id']);
}

?>


<center>
<h1 class="title">E Hotel Customer Login</h1>


<form action="" method="post" class='loginform'>
  <div class="form-group">
    <input type="number" class="form-control" name="username" placeholder="Enter your username" required>
   </div>
  <div class="form-group">
    <input type="password" class="form-control" name="password" placeholder="Password" required>
  </div>
  <button type="submit" class="btn btn-outline-success" value="Submit">Submit</button>
</form>
</center>
<?php


if ( ! empty( $_POST ) ) {
    if ( isset( $_POST['username'] ) && isset( $_POST['password'] ) ) {
      $query = 'SELECT exists(Select * FROM public.Customer where SSN='.$_POST['username']." and password='".$_POST['password']."')";
      $result = pg_query($query) ;
      $row = pg_fetch_row($result);
      
      if($row[0]==="f"){
      $_SESSION['message'] = "Log in failed";
      header("Location: customer_login.php");
      } else{
        $_SESSION['user_id'] = $_POST['username'];
        $_SESSION['permission'] = "customer";
        
        header("Location: customer_main.php");
      }

      
    }
}
?>


</body>
</html>