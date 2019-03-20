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
        <h1 class="title">Amenity Edit</h1>
        <?php

        if (!empty($_POST)) {
          if (isset($_POST['id'])) {

            $query = 'Select * FROM public.Amenity where room_id=' . $_POST['id'];
            $result = pg_query($query);
            $row = pg_fetch_row($result);
            echo '<form action="amenity_edit_request.php" method="post" class="loginform" >
            <div class="form-group">
            <label for="room_id">Room Id:</label>
            <input type="text" class="form-control" name="room_id" placeholder="Room Id" value="' . $row[0] . '" required readonly>
             </div>
             <div class="form-group">
            <label for="name">Name:</label>
            <input type="text" class="form-control" name="name" placeholder="Name" value="' . $row[1] . '" required readonly>
             </div>
             <div class="form-group">
            <label for="description">Description:</label>
            <input type="text" class="form-control" name="description" placeholder="Description" value="' . $row[2] . '" required>
             </div>
              <button type="submit" class="btn btn-primary" value="Submit">Submit</button>
              <a href="../manager_chains" class="btn btn-primary">Cancel</button>
            </form>';
          }
        }


        ?>
    </center>



</body>

</html> 