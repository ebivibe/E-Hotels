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
    <?php
    
    if (!empty($_POST)) {
        if (isset($_POST["id"])) {
          $query = 'delete from public.Employee where SSN=' . $_POST["id"];
          $result = pg_query($query);
          print_r($query);

          if (!$result) {
            $_SESSION['message'] = "Edit failed";
            header("Location: ../manager_employees.php");
          } else {
            $_SESSION['message'] = "Edit Successful";
            header("Location: ../manager_employees.php");
          }
        }
      }


    ?>
</body>

</html> 