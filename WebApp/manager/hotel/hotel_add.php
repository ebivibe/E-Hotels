
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


<center>
<h1 class="title">Hotel Add</h1>
<form action="" method="post" class="loginform" >
            <div class="form-group">
            <label for="chain_id">Chain Id:</label>
              <input type="number" class="form-control" name="chain_id" placeholder="Chain Id" required>
             </div>
             <div class="form-group">
            <label for="chain_id">Category:</label>
              <input type="number" class="form-control" name="category" placeholder="Category" min="1" max="5" required>
             </div>
          <div class="form-group">
           <label for="email">Email:</label>
           <input type="text" class="form-control" name="email" placeholder="Email" required>
          </div>
             <div class="form-group">
             <label for="email">Street Number:</label>
              <input type="number" class="form-control" name="streetnumber" placeholder="Street Number" required>
            </div>
            <div class="form-group">
            <label for="email">Street Name:</label>
              <input type="text" class="form-control" name="streetname" placeholder="Street Name"  required>
            </div>
            <div class="form-group">
            <label for="email">Unit:</label>
              <input type="text" class="form-control" name="unit" placeholder="Unit" >
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
            <button type="submit" class="btn btn-primary" value="Submit">Submit</button>
          </form>



</center>

<?php
if ( ! empty( $_POST ) ) {
    if ( isset( $_POST["chain_id"] ) ) { 
        $query = 'insert into public.Hotel(chain_id, category, email, street_number, street_name, unit, city, province, country, zip) values(
         '.$_POST['chain_id'].', '.$_POST['category'].', \''.$_POST['email'].'\',  '.$_POST['streetnumber'].', \''.$_POST['streetname'].'\', \''.$_POST['unit'].'\', \''.$_POST['city'].'\',
        \''.$_POST['province'].'\', \''.$_POST['country'].'\', \''.$_POST['zip'].'\')';
        $result = pg_query($query) ;
        print_r($query);
        //exit;
           
      if(!$result){
        echo "<script>alert('Edit Failed');</script>";
        header("Location: ../manager_hotels.php");
      } else{
        echo "<script>alert('Edit Success');</script>";
        header("Location: ../manager_hotels.php");
      }
    }
}


?>



</body>
</html>