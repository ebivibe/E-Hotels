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
        
        <form action="booking_add_request.php" method="post" class="loginform">
        <?php
                if (!empty($_POST)) {
                  if (isset($_POST["id"])) {
                    echo '<input type="hidden" class="form-control" name="room_id"  value="' . $_POST["id"] . '" >';
                  }
                }
                ?>
            
            <div class="form-group">
                <label for="email">Check Out Date:</label>
                <?php
                //date_picker("check_out_date", "Enter the check out date");
                echo " <input type=\"date\" class=\"form-control\" name=\"check_out_date\" placeholder=\"Check Out Date\"  required>";
                ?>
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
            <?php 
            echo '<input type="hidden" class="form-control" name="employee_ssn" value='.$_SESSION['user_id'].' required>';
            ?>
            <button type="submit" class="btn btn-outline-success" value="Submit">Submit</button>
        </form>



    </center>

   


</body>

</html> 