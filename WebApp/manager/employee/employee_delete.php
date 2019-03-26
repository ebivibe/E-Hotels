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
            echo "<script>alert('Edit Failed');</script>";
            header("Location: ../manager_employees.php");
          } else {
            echo "<script>alert('Edit Success');</script>";
            header("Location: ../manager_employees.php");
          }
        }
      }


    ?>
</body>

</html> 