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
        <h1 class="title">Room Add</h1>
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
                <label for="chain_id">Room Number:</label>
                <input type="number" class="form-control" name="room_number" placeholder="Room Number" required>
            </div>
            <div class="form-group">
                <label for="email">Price:</label>
                <input type="number" class="form-control" name="price" placeholder="Price" required>
            </div>
            <div class="form-group">
                <label for="email">Capacity:</label>
                <input type="number" class="form-control" name="capacity" placeholder="Capacity" required>
            </div>
            <div class="form-group">
                <label for="sea_view">Sea View:</label>
                <select name="sea_view" class="form-control">
                    <option class="dropdown-item" value="true">Yes</option>
                    <option class="dropdown-item" value="false">No</option>
                </select>
            </div>
            <div class="form-group">
                <label for="mountain_view">Montain View:</label>
                <select name="mountain_view" class="form-control">
                    <option class="dropdown-item" value="true">Yes</option>
                    <option class="dropdown-item" value="false">No</option>
                </select>
            </div>
            <div class="form-group">
                <label for="damages">Damages:</label>
                <select name="damages" class="form-control">
                    <option class="dropdown-item" value="true">Yes</option>
                    <option class="dropdown-item" value="false">No</option>
                </select>
            </div>
            <div class="form-group">
                <label for="can_be_extended">Can be extended:</label>
                <select name="can_be_extended" class="form-control">
                    <option class="dropdown-item" value="true">Yes</option>
                    <option class="dropdown-item" value="false">No</option>
                </select>
            </div>
            <button type="submit" class="btn btn-outline-success" value="Submit">Submit</button>
            <a href="../manager_chains" class="btn btn-outline-success">Cancel</button>
        </form>



    </center>

    <?php
    if (!empty($_POST)) {
      if (isset($_POST["hotel_id"])) {
        $query = 'insert into public.Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) values(
         ' . $_POST['room_number'] . ', ' . $_POST['hotel_id'] . ', ' . $_POST['price'] . ', ' . $_POST['capacity'] . ', 
         \'' . $_POST['sea_view'] . '\', \'' . $_POST['mountain_view'] . '\', \'' . $_POST['damages'] . '\', \'' . $_POST['can_be_extended'] . '\' )';
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