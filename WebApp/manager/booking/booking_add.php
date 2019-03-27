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


    <center>
        <h1 class="title">Booking Add</h1>
        
        <form action="" method="post" class="loginform">
        <?php
                if (!empty($_POST)) {
                  if (isset($_POST["id"])) {
                    echo '<input type="hidden" class="form-control" name="room_id"  value="' . $_POST["id"] . '" >';
                  }
                }
                ?>
            <div class="form-group">
                <label for="name">Reservation Date:</label>
                <input type="text" class="form-control" name="reservation_date" placeholder="Reservation Date" required>
            </div>
            <div class="form-group">
                <label for="email">Check In Date:</label>
                <input type="text" class="form-control" name="check_in_date" placeholder="Check In Date" required>
            </div>
            <div class="form-group">
                <label for="email">Check Out Date:</label>
                <input type="text" class="form-control" name="check_out_date" placeholder="Check Out Date" required>
            </div>
            <div class="form-group">
                <label for="checked_in">Checked In:</label>
                <select name="checked_in" class="form-control" >
                    <option class="dropdown-item" value="true">Yes</option>
                    <option class="dropdown-item" value="false">No</option>
                </select>
            </div>
            <div class="form-group">
                <label for="paid">Paid:</label>
                <select name="paid" class="form-control">
                    <option class="dropdown-item" value="true">Yes</option>
                    <option class="dropdown-item" value="false">No</option>
                </select>
            </div>
            <div class="form-group">
                <label for="customer_ssn">Customer SSN:</label>
                <input type="number" class="form-control" name="customer_ssn" placeholder="Customer SSN"  required >
            </div>
            <div class="form-group">
                <label for="employee_ssn">Employee SSN:</label>
                <input type="number" class="form-control" name="employee_ssn" placeholder="Employee SSN" required>
            </div>
            <button type="submit" class="btn btn-outline-success" value="Submit">Submit</button>
        </form>



    </center>

    <?php
    if (!empty($_POST)) {
        if (isset($_POST["room_id"])) {
            $query = 'insert into public.BookingRental(reservation_date, check_in_date, check_out_date, checked_in, paid, room_id, customer_ssn, employee_ssn) values(
                \'' . $_POST['reservation_date'] . '\', \'' . $_POST['check_in_date'] . '\', \'' . $_POST['check_out_date'] . '\', \'' . $_POST['checked_in'] . '\',
                \'' . $_POST['paid'] . '\', ' . $_POST['room_id'] . ', ' . $_POST['customer_ssn'] . ', ' . $_POST['employee_ssn'] . ')';
            $result = pg_query($query);
            print_r($query);

            if (!$result) {
                $_SESSION['message'] = "Edit failed";
                header("Location: ../manager_customers.php");
            } else {
                $_SESSION['message'] = "Edit Successful";
                header("Location: ../manager_customers.php");
            }
        }
    }


    ?>



</body>

</html> 