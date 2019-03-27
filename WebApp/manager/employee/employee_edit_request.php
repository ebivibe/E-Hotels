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
      if (isset($_POST["ssn"])) {
        $query = 'update public.Employee set name=\'' . $_POST['name'] . '\', hotel_id=' . $_POST['hotel_id'] . ',
        street_number=\'' . $_POST['streetnumber'] . '\',
        street_name=\'' . $_POST['streetname'] . '\',  unit=\'' . $_POST['unit'] . '\',  city=\'' . $_POST['city'] . '\',
        province=\'' . $_POST['province'] . '\',   country=\'' . $_POST['country'] . '\',  zip=\'' . $_POST['zip'] . '\',
        password=\'' . $_POST['password'] . '\' where SSN=' . $_POST['ssn'];
        print_r($query);
        $result = pg_query($query);
        print_r($result);

        //exit;

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