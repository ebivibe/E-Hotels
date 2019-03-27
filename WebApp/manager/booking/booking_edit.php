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
        <h1 class="title">Customer Edit</h1>
        <?php

        if (!empty($_POST)) {
            if (isset($_POST['id'])) {

                $query = 'Select * FROM public.BookingRental where booking_id=' . $_POST['id'];
                $result = pg_query($query);
                $row = pg_fetch_row($result);
                echo "<form action=\"booking_edit_request.php\" method=\"post\" class=\"loginform\" >
            <div class=\"form-group\">
            <label for=\"ssn\">Booking id:</label>
            <input type=\"text\" class=\"form-control\" name=\"booking_id\" placeholder=\"Booking Id\" value=" . $row[0] . " required readonly>
             </div>
            <div class=\"form-group\">
            <label for=\"name\">Reservation Date:</label>
              <input type=\"text\" class=\"form-control\" name=\"reservation_date\" placeholder=\"Reservation Date\" value=" . $row[1] . " required>
             </div>
             <div class=\"form-group\">
             <label for=\"email\">Check In Date:</label>
              <input type=\"text\" class=\"form-control\" name=\"check_in_date\" placeholder=\"Check In Date\" value=" . $row[2] . " required>
            </div>
            <div class=\"form-group\">
            <label for=\"email\">Check Out Date:</label>
              <input type=\"text\" class=\"form-control\" name=\"check_out_date\" placeholder=\"Check Out Date\" value=" . $row[3] . " required>
            </div>
            <div class=\"form-group\">
            <label for=\"checked_in\">Checked In:</label>
            <select name=\"checked_in\" class=\"form-control\" value=\"".$row[4]."\">
            <option class=\"dropdown-item\" value=\"t\" ";  if ($row[4] == 't') echo 'selected = "selected"'; echo ">Yes</option>
            <option class=\"dropdown-item\" value=\"f\" ";  if ($row[4] == 'f') echo 'selected = "selected"'; echo ">No</option>  
           
            </select>
            </div>
            <div class=\"form-group\">
            <label for=\"paid\">Paid:</label>
            <select name=\"paid\" class=\"form-control\" value=" . $row[5] . ">
            <option class=\"dropdown-item\" value=\"t\" ";  if ($row[5] == 't') echo 'selected = "selected"'; echo ">Yes</option>
            <option class=\"dropdown-item\" value=\"f\" ";  if ($row[5] == 'f') echo 'selected = "selected"'; echo ">No</option>  
            </select>
            </div>
             <div class=\"form-group\">
             <label for=\"customer_ssn\">Customer SSN:</label>
             <input type=\"text\" class=\"form-control\" name=\"customer_ssn\" placeholder=\"Customer SSN\" value=" . $row[7] . " required readonly>
             </div>
             <div class=\"form-group\">
             <label for=\"employee_ssn\">Employee SSN:</label>
             <input type=\"text\" class=\"form-control\" name=\"employee_ssn\" placeholder=\"Employee SSN\" value=" . $row[8] . " required>
            </div>
            <button type=\"submit\" class=\"btn btn-outline-success\" value=\"Submit\">Submit</button>
          </form>";
            }
        }
        ?>
    </center>



</body>

</html> 