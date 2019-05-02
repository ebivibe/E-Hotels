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
            $query = 'insert into public.Employee(SSN, name, hotel_id, street_number, street_name, unit, city, province, country, zip, password) values(
        ' . $_POST['ssn'] . ' , \'' . $_POST['name'] . '\', ' . $_POST['hotel_id'] . ' ,' . $_POST['streetnumber'] . ', \'' . $_POST['streetname'] . '\', \'' . $_POST['unit'] . '\', \'' . $_POST['city'] . '\',
        \'' . $_POST['province'] . '\', \'' . $_POST['country'] . '\', \'' . $_POST['zip'] . '\',
        \'' . $_POST['password'] . '\')';
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