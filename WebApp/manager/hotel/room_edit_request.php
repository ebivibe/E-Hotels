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
        $query = 'update public.Room set room_number=' . $_POST['room_number'] . ', price=' . $_POST['price'] . ',
        capacity=' . $_POST['capacity'] . ',
        sea_view=\'' . $_POST['sea_view'] . '\',  mountain_view=\'' . $_POST['mountain_view'] . '\',
        damages=\'' . $_POST['damages'] . '\',   can_be_extended=\'' . $_POST['can_be_extended'] . '\'
        where room_id=' . $_POST['room_id'];
        print_r($query);
        $result = pg_query($query);
        print_r($result);

        // exit;

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