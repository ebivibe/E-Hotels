<?php
require_once("../../../helpers/login_check.php");
?>


<!DOCTYPE html>
<html>

<head>
    <?php

    include("../../../helpers/imports.php");
    include("../../../helpers/common.php");
    ?>
</head>

<body>


    <center>
        <h1 class="title">Role Edit</h1>
        <?php

        if (!empty($_POST)) {
          if (isset($_POST['id'])) {

            $query = 'Select * FROM public.Role where role_id=' . $_POST['id'];
            $result = pg_query($query);
            $row = pg_fetch_row($result);
            echo '<form action="role_edit_request.php" method="post" class="loginform" >
            <div class="form-group">
            <label for="room_id">Role Id:</label>
            <input type="text" class="form-control" name="role_id" placeholder="Role Id" value="' . $row[0] . '" required readonly>
             </div>
             <div class="form-group">
            <label for="name">Name:</label>
            <input type="text" class="form-control" name="name" placeholder="Name" value="' . $row[1] . '" required>
             </div>
             <div class="form-group">
            <label for="description">Description:</label>
            <input type="text" class="form-control" name="description" placeholder="Description" value="' . $row[2] . '" required>
             </div>
              <button type="submit" class="btn btn-outline-success" value="Submit">Submit</button>
              <a href="../manager_chains" class="btn btn-outline-success">Cancel</a>
            </form>';
          }
        }


        ?>
    </center>



</body>

</html> 