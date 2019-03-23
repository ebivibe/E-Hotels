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
      if (isset($_POST["ssn"])) {
        $query = 'Select * FROM public.Manages where ssn=' . $_POST['ssn'];
        $result = pg_query($query);
        if (pg_num_rows($result) == 0) {
            $query = "Insert into public.Manages(ssn, hotel_id) values(".$_POST['ssn'].", (select hotel_id from public.Employee where ssn=".$_POST['ssn']."))";
            $result = pg_query($query);
            if (!$result) {
                echo "<script>alert('Edit Failed');</script>";
                header("Location: ../../manager_employees.php");
              } else {
                echo "<script>alert('Edit Success');</script>";
                header("Location: ../../manager_employees.php");
              }
            
        } else {
            $query = "Delete from public.Manages where ssn=".$_POST['ssn'];
            $result = pg_query($query);
            if (!$result) {
                echo "<script>alert('Edit Failed');</script>";
                header("Location: ../../manager_employees.php");
              } else {
                echo "<script>alert('Edit Success');</script>";
                header("Location: ../../manager_employees.php");
              }
        }
        //exit;
      }
    }


    ?>
</body>

</html> 