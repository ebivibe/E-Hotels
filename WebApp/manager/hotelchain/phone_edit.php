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
        <h1 class="title">Hotel Chain Phone Edit</h1>
        <?php

        if (!empty($_POST)) {
          if (isset($_POST['id'])) {

            $query = 'Select * FROM public.ChainPhoneNumber where chain_id=' . $_POST['id'].' and phone_number=\''. $_POST['number'].'\'';
            $result = pg_query($query);
            $row = pg_fetch_row($result);
            echo '<form action="" method="post" class="loginform" >
            <input type="hidden" name="prev_number" value="'.$_POST['number'].'"/>
            <div class="form-group">
            <label for="room_id">Hotel Chain Id:</label>
            <input type="text" class="form-control" name="chain_id" placeholder="Room Id" value="' . $row[0] . '" required readonly>
             </div>
             <div class="form-group">
            <label for="name">Phone Number:</label>
            <input type="text" class="form-control" name="phone_number" placeholder="Phone Number" value="' . $row[1] . '" required>
             </div>
              <button type="submit" class="btn btn-outline-success" value="Submit">Submit</button>
              <a href="../manager_chains" class="btn btn-outline-success">Cancel</a>
            </form>';
          }
        }


        ?>
    </center>


</body>

<?php
    if (!empty($_POST)) {
      if (isset($_POST["chain_id"]) && isset($_POST["phone_number"])) {
        $query = 'update public.ChainPhoneNumber set phone_number=\'' . $_POST['phone_number'].'\'
        where chain_id=' . $_POST['chain_id'] . ' and phone_number=\'' . $_POST['prev_number'].'\'';
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

</html> 