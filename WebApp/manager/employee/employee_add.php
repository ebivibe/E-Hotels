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
        <h1 class="title">Employee Add</h1>
        <form action="employee_add_request" method="post" class="loginform">
            <div class="form-group">
                <label for="ssn">SSN:</label>
                <input type="number" class="form-control" name="ssn" placeholder="SSN" required>
            </div>
            <?php echo "<div class=\"form-group\">
            <label for=\"hotel_id\">Hotel ID:</label>
            <select name=\"hotel_id\" class=\"form-control\" >";
            $query = 'SELECT hotel_id FROM public.Hotel order by hotel_id';
            $result = pg_query($query) or die('Query failed: ' . pg_last_error());
            while ($line = pg_fetch_array($result, null, PGSQL_ASSOC)) {
                echo "<option class=\"dropdown-item\" value=\"" . $line["hotel_id"] . "\" >" . $line["hotel_id"] . "</option>";
            }
            echo "</select></div>";
            ?>
            <div class="form-group">
                <label for="name">Name:</label>
                <input type="text" class="form-control" name="name" placeholder="Name" required>
            </div>
            <div class="form-group">
                <label for="email">Street Number:</label>
                <input type="number" class="form-control" name="streetnumber" placeholder="Street Number" required>
            </div>
            <div class="form-group">
                <label for="email">Street Name:</label>
                <input type="text" class="form-control" name="streetname" placeholder="Street Name" required>
            </div>
            <div class="form-group">
                <label for="email">Unit:</label>
                <input type="text" class="form-control" name="unit" placeholder="Unit">
            </div>
            <div class="form-group">
                <label for="email">City:</label>
                <input type="text" class="form-control" name="city" placeholder="City" required>
            </div>
            <div class="form-group">
                <label for="email">Province:</label>
                <input type="text" class="form-control" name="province" placeholder="Province" required>
            </div>
            <div class="form-group">
                <label for="email">Country:</label>
                <input type="text" class="form-control" name="country" placeholder="Country" required>
            </div>
            <div class="form-group">
                <label for="email">Zip:</label>
                <input type="text" class="form-control" name="zip" placeholder="Zip" required>
            </div>
            <div class="form-group">
                <label for="email">Password:</label>
                <input type="text" class="form-control" name="password" placeholder="Password" minlength="5" required>
            </div>
            <button type="submit" class="btn btn-outline-success" value="Submit">Submit</button>
        </form>



    </center>

    



</body>

</html> 