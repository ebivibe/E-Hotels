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
        <h1 class="title">Role Add</h1>
        <form action="" method="post" class="loginform">
            <div class="form-group">
                <?php
                if (!empty($_POST)) {
                  if (isset($_POST["id"])) {
                    echo '<input type="number" class="form-control" name="ssn"  value="' . $_POST["id"] . '" hidden >';
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

            <button type="submit" class="btn btn-outline-success" value="Submit">Submit</button>
            <a href="../manager_chains" class="btn btn-outline-success">Cancel</a>
        </form>



    </center>

    <?php
    if (!empty($_POST)) {
      if (isset($_POST["ssn"])) {
        $query = "With A as (insert into public.role(name, description) values('".$_POST[name]."', '".$_POST[description]."') returning role_id)
             insert into public.employeerole(employee_ssn, role_id) values('".$_POST[ssn]."', (select role_id from A))";
        $result = pg_query($query);
        print_r($query);
       // exit;

        if (!$result) {
          $_SESSION['message'] = "Edit failed";
          header("Location: ../../manager_employees.php");
        } else {
          $_SESSION['message'] = "Edit Successful";
          header("Location: ../../manager_employees.php");
        }
      }
    }


    ?>



</body>

</html> 