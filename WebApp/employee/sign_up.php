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
  if(isset($_SESSION['message'])){
    echo '<div class="alert alert-warning alert-dismissible fade show" role="alert">'.$_SESSION['message'].'
    <button type="button" class="close" data-dismiss="alert" aria-label="Close">
    <span aria-hidden="true">&times;</span>
  </button>
    </div>';
    unset($_SESSION['message']);
}
?>
    <center>
        <h1 class="title">Customer Add</h1>
        <form action="" method="post" class="loginform">
            <div class="form-group">
                <label for="ssn">SSN:</label>
                <input type="number" class="form-control" name="ssn" placeholder="SSN" required>
            </div>
            <div class="form-group">
                <label for="name">Hotel Id:</label>
                <input type="number" class="form-control" name="hotel_id" placeholder="Hotel Id" required>
            </div>
            <div class="form-group">
                <label for="name">Name:</label>
                <input type="text" class="form-control" name="name" placeholder="Name" required>
            </div>
            <div class="form-group">
                <label for="email">Street Number:</label>
                <input type="number" class="form-control" name="streetnumber" placeholder="Street Number" required>
            </div>
            <div class="form-group">
                <label for="email">Street Name:</label>
                <input type="text" class="form-control" name="streetname" placeholder="Street Name" required>
            </div>
            <div class="form-group">
                <label for="email">Unit:</label>
                <input type="text" class="form-control" name="unit" placeholder="Unit">
            </div>
            <div class="form-group">
                <label for="email">City:</label>
                <input type="text" class="form-control" name="city" placeholder="City" required>
            </div>
            <div class="form-group">
                <label for="email">Province:</label>
                <input type="text" class="form-control" name="province" placeholder="Province" required>
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
                <input type="text" class="form-control" name="password" placeholder="Password"  minlength="5" required>
            </div>
            <button type="submit" class="btn btn-outline-success" value="Submit">Submit</button>
        </form>



    </center>

    <?php
    if (!empty($_POST)) {
      if (isset($_POST["ssn"])) {
        $query = 'insert into public.Employee(SSN, name, hotel_id, street_number, street_name, unit, city, province, country, zip, password) values(
        ' . $_POST['ssn'] . ' , \'' . $_POST['name'] . '\', ' . $_POST['hotel_id'] . ' ,' . $_POST['streetnumber'] . ', \'' . $_POST['streetname'] . '\', \'' . $_POST['unit'] . '\', \'' . $_POST['city'] . '\',
        \'' . $_POST['province'] . '\', \'' . $_POST['country'] . '\', \'' . $_POST['zip'] . '\',
        \'' . $_POST['password'] . '\')';
        $result = pg_query($query);
        print_r($query);

        if (!$result) {
          
         $_SESSION['message'] = "Sign up failed";
          header("Location: sign_up.php");
        } else {
          $_SESSION['user_id'] = $_POST['ssn'];
          header("Location: employee_main.php");
        }
      }
    }


    ?>



</body>

</html> 