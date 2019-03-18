
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


<center>
<h1 class="title">Customer Add</h1>
<form action="" method="post" class="loginform" >
        <div class="form-group">
            <label for="ssn">SSN:</label>
            <input type="text" class="form-control" name="ssn" placeholder="SSN" required>
            </div>
            <div class="form-group">
            <label for="name">Name:</label>
              <input type="text" class="form-control" name="name" placeholder="Name" required>
             </div>
             <div class="form-group">
             <label for="email">Street Number:</label>
              <input type="text" class="form-control" name="streetnumber" placeholder="Street Number" required>
            </div>
            <div class="form-group">
            <label for="email">Street Name:</label>
              <input type="text" class="form-control" name="streetname" placeholder="Street Name"  required>
            </div>
            <div class="form-group">
            <label for="email">Unit:</label>
              <input type="text" class="form-control" name="unit" placeholder="Unit" required>
             </div>
             <div class="form-group">
             <label for="email">City:</label>
             <input type="text" class="form-control" name="city" placeholder="City" required>
             </div>
             <div class="form-group">
             <label for="email">Province:</label>
             <input type="text" class="form-control" name="province" placeholder="Province"  required>
            </div>
            <div class="form-group">
            <label for="email">Country:</label>
            <input type="text" class="form-control" name="country" placeholder="Country" required>
            </div>
            <div class="form-group">
            <label for="email">Zip:</label>
            <input type="text" class="form-control" name="zip" placeholder="Zip" required>
           </div>
           <div class="form-group">
           <label for="email">Password:</label>
           <input type="text" class="form-control" name="password" placeholder="Password" required>
          </div>
            <button type="submit" class="btn btn-primary" value="Submit">Submit</button>
          </form>



</center>

<?php
if ( ! empty( $_POST ) ) {
    if ( isset( $_POST["ssn"] ) ) { 
        $query = 'insert into public.Customer(SSN, name, street_number, street_name, unit, city, province, country, zip, password) values(
        '.$_POST['ssn'].' , \''.$_POST['name'].'\', '.$_POST['streetnumber'].', \''.$_POST['streetname'].'\', \''.$_POST['unit'].'\', \''.$_POST['city'].'\',
        \''.$_POST['province'].'\', \''.$_POST['country'].'\', \''.$_POST['zip'].'\',
        \''.$_POST['password'].'\')';
        $result = pg_query($query) ;
        print_r($query);
           
      if(!$result){
        echo "<script>alert('Edit Failed');</script>";
        header("Location: manager_customers.php");
      } else{
        echo "<script>alert('Edit Success');</script>";
        header("Location: manager_customers.php");
      }
    }
}


?>



</body>
</html>