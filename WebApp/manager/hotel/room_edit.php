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

            $query = 'Select * FROM public.Room where room_id=' . $_POST['id'];
            $result = pg_query($query);
            $row = pg_fetch_row($result);
            echo '<form action="room_edit_request.php" method="post" class="loginform" >
            <div class="form-group">
            <label for="room_id">Room Id:</label>
            <input type="text" class="form-control" name="room_id" placeholder="Room Id" value="' . $row[0] . '" required readonly>
             </div>
             <div class="form-group">
             <label for="hotel_id">Hotel Id:</label>
             <input type="text" class="form-control" name="hotel_id" placeholder="Hotel Id" value="' . $row[2] . '" required readonly>
              </div>
              <div class="form-group">
              <label for="chain_id">Room Number:</label>
                <input type="number" class="form-control" name="room_number" value="' . $row[1] . '" placeholder="Room Number"  required>
               </div>
            <div class="form-group">
             <label for="email">Price:</label>
             <input type="number" class="form-control" name="price" value="' . $row[3] . '" placeholder="Price" required>
            </div>
               <div class="form-group">
               <label for="email">Capacity:</label>
                <input type="number" class="form-control" name="capacity" value="' . $row[4] . '" placeholder="Capacity" required>
              </div>
              <div class="form-group">
              <label for="sea_view">Sea View:</label>
              <select name="sea_view" class="form-control" value="' . $row[5] . '">
              <option class="dropdown-item" value="t" ';  if ($row[5] == 't') echo 'selected = "selected"'; echo '>Yes</option>
            <option class="dropdown-item" value="f" ';  if ($row[5] == 'f') echo 'selected = "selected"'; echo '>No</option>  
           
              </select>
              </div>
              <div class="form-group">
              <label for="mountain_view">Montain View:</label>
              <select name="mountain_view" class="form-control" value="' . $row[6] . '">
              <option class="dropdown-item" value="t" ';  if ($row[6] == 't') echo 'selected = "selected"'; echo '>Yes</option>
              <option class="dropdown-item" value="f" ';  if ($row[6] == 'f') echo 'selected = "selected"'; echo '>No</option>  
             
              </select>
              </div>
              <div class="form-group">
              <label for="damages">Damages:</label>
              <select name="damages" class="form-control" value="' . $row[7] . '">
              <option class="dropdown-item" value="t" ';  if ($row[7] == 't') echo 'selected = "selected"'; echo '>Yes</option>
              <option class="dropdown-item" value="f" ';  if ($row[7] == 'f') echo 'selected = "selected"'; echo '>No</option>  
             
              </select>
              </div>
              <div class="form-group">
              <label for="can_be_extended">Can be extended:</label>
              <select name="can_be_extended" class="form-control" value="' . $row[8] . '">
              <option class="dropdown-item" value="t" ';  if ($row[8] == 't') echo 'selected = "selected"'; echo '>Yes</option>
              <option class="dropdown-item" value="f" ';  if ($row[8] == 'f') echo 'selected = "selected"'; echo '>No</option>  
             
              </select>
              </div>
              <button type="submit" class="btn btn-primary" value="Submit">Submit</button>
              <a href="../manager_chains" class="btn btn-primary">Cancel</button>
            </form>';
          }
        }


        ?>
    </center>



</body>

</html> 