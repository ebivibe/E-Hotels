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
    <?php
    if (!empty($_POST)) {
      if (isset($_POST["role_id"])) {
        $query = 'update public.Role set name=\'' . $_POST['name'] . '\', description=\'' . $_POST['description'] . '\'
        where role_id=' . $_POST['role_id'];
        print_r($query);
        $result = pg_query($query);
        print_r($result);

        //exit;

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