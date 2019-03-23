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
        <h1 class="title">Phone Add</h1>
        <form action="" method="post" class="loginform">
            <div class="form-group">
                <?php
                if (!empty($_POST)) {
                  if (isset($_POST["id"])) {
                    echo '<input type="number" class="form-control" name="hotel_id"  value="' . $_POST["id"] . '" hidden >';
                  }
                }
                ?>
            </div>
            <div class="form-group">
                <label for="name">Phone Number:</label>
                <input type="text" class="form-control" name="phone_number" placeholder="Phone Number" required>
            </div>
            

            <button type="submit" class="btn btn-primary" value="Submit">Submit</button>
            <a href="../manager_chains" class="btn btn-primary">Cancel</a>
        </form>



    </center>

    <?php
    if (!empty($_POST)) {
      if (isset($_POST["hotel_id"]) && isset($_POST["phone_number"])) {
        $query = 'insert into public.HotelPhoneNumber(hotel_id, phone_number) values(
         ' . $_POST['hotel_id'] . ', \''. $_POST['phone_number']. '\')';
        $result = pg_query($query);
        print_r($query);
        //exit;

        if (!$result) {
          echo "<script>alert('Edit Failed');</script>";
          header("Location: ../manager_chains.php");
        } else {
          echo "<script>alert('Edit Success');</script>";
          header("Location: ../manager_chains.php");
        }
      }
    }


    ?>



</body>

</html> 