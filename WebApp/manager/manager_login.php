
<!DOCTYPE html>
<html>
<head>
<?php
include("../helpers/imports.php");
?>
</head>
<body>


<center>
<h1 class="title">E Hotel Admin Login</h1>


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
        if ($_POST['username'] === "admin" && $_POST['password']==="admin"){
            $_SESSION['user_id'] = $_POST['username'];
            header("Location: manager_main.php");
        }
        else{
            echo "<script>alert('Login Failed');</script>";
        }
      
    }
}
/*
if ( ! empty( $_POST ) ) {
  if ( isset( $_POST['username'] ) && isset( $_POST['password'] ) ) {
    $query = 'SELECT exists(Select * FROM public.Employee where SSN='.$_POST['username'].' and password=\''.$_POST['password'].'\') and exists(Select * FROM public.Manages where SSN='.$_POST['username'].') ';
    $result = pg_query($query) ;
  
    
    if(!$result){
      echo "<script>alert('Login Failed');</script>";
    } else{
     // $row = pg_fetch_row($result)
      $_SESSION['user_id'] = $_POST['username'];
      header("Location: customer_main.php");
    }
 
  }
}
*/
?>


</body>
</html>