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
        <h1 class="title">Amenity Add</h1>
        <form action="" method="post" class="loginform">
            <div class="form-group">
                <?php
                if (!empty($_POST)) {
                  if (isset($_POST["id"])) {
                    echo '<input type="number" class="form-control" name="room_id"  value="' . $_POST["id"] . '" hidden >';
                  }
                }
                ?>
            </div>
            <div class="form-group">
                <label for="name">Name:</label>
                <input type="text" class="form-control" name="name" placeholder="Name" required>
            </div>
            <div class="form-group">
                <label for="description">Description:</label>
                <input type="text" class="form-control" name="description" placeholder="Description">
            </div>

            <button type="submit" class="btn btn-primary" value="Submit">Submit</button>
            <a href="../manager_chains" class="btn btn-primary">Cancel</button>
        </form>



    </center>

    <?php
    if (!empty($_POST)) {
      if (isset($_POST["room_id"])) {
        $query = 'insert into public.Amenity(room_id, name, description) values(
         ' . $_POST['room_id'] . ', \'' . $_POST['name'] . '\', \'' . $_POST['description'] . '\' )';
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