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
      if (isset($_POST["room_id"])) {
        $query = 'update public.Amenity set description=\'' . $_POST['description'] . '\'
        where room_id=' . $_POST['room_id'] . ' and name=\'' . $_POST['name'] . '\'';
        print_r($query);
        $result = pg_query($query);
        print_r($result);

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