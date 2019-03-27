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
        <h1 class="title">Hotel Edit</h1>
        <?php

        if (!empty($_POST)) {
          if (isset($_POST['id'])) {

            $query = 'Select * FROM public.Hotel where hotel_id=' . $_POST['id'];
            $result = pg_query($query);
            $row = pg_fetch_row($result);
            echo "<form action=\"hotel_edit_request.php\" method=\"post\" class=\"loginform\" >
            <div class=\"form-group\">
            <label for=\"hotel_id\">Hotel Id:</label>
            <input type=\"text\" class=\"form-control\" name=\"hotel_id\" placeholder=\"Hotel Id\" value=" . $row[0] . " required readonly>
             </div>
             <div class=\"form-group\">
             <label for=\"chain_id\">Chain Id:</label>
             <input type=\"text\" class=\"form-control\" name=\"chain_id\" placeholder=\"Chain Id\" value=" . $row[1] . " required readonly>
              </div>
             <div class=\"form-group\">
            <label for=\"category\">Category:</label>
              <input type=\"number\" class=\"form-control\" name=\"category\" placeholder=\"Category\" value=" . $row[2] . " min=\"1\" max=\"5\" required>
             </div>
             <div class=\"form-group\">
            <label for=\"chain_name\">Email:</label>
              <input type=\"text\" class=\"form-control\" name=\"email\" placeholder=\"Email\" value=" . $row[3] . " required>
             </div>
             <div class=\"form-group\">
             <label for=\"email\">Street Number:</label>
              <input type=\"number\" class=\"form-control\" name=\"streetnumber\" placeholder=\"Street Number\" value=" . $row[4] . " required>
            </div>
            <div class=\"form-group\">
            <label for=\"email\">Street Name:</label>
              <input type=\"text\" class=\"form-control\" name=\"streetname\" placeholder=\"Street Name\" value=" . $row[5] . " required>
            </div>
            <div class=\"form-group\">
            <label for=\"email\">Unit:</label>
              <input type=\"text\" class=\"form-control\" name=\"unit\" placeholder=\"Unit\" value=" . $row[6] . " >
             </div>
             <div class=\"form-group\">
             <label for=\"email\">City:</label>
             <input type=\"text\" class=\"form-control\" name=\"city\" placeholder=\"City\" value=" . $row[7] . " required>
             </div>
             <div class=\"form-group\">
             <label for=\"email\">Province:</label>
             <input type=\"text\" class=\"form-control\" name=\"province\" placeholder=\"Province\" value=" . $row[8] . " required>
            </div>
            <div class=\"form-group\">
            <label for=\"email\">Country:</label>
            <input type=\"text\" class=\"form-control\" name=\"country\" placeholder=\"Country\" value=" . $row[9] . " required>
            </div>
            <div class=\"form-group\">
            <label for=\"email\">Zip:</label>
            <input type=\"text\" class=\"form-control\" name=\"zip\" placeholder=\"Zip\" value=" . $row[10] . " required>
           </div>
            <button type=\"submit\" class=\"btn btn-outline-success\" value=\"Submit\">Submit</button>
            <a href=\"../manager_chains\" class=\"btn btn-outline-success\">Cancel</button>
          </form>";
          }
        }



        ?>
    </center>



</body>

</html> 