<?php
include("../../helpers/imports.php");
include("../../helpers/common.php");
    if (!empty($_POST)) {
      if (isset($_POST["delete_id"])) {
        $query = 'delete from public.HotelChain where chain_id=' . $_POST["delete_id"];
        $result = pg_query($query);

        if (!$result) {
          echo "<script>alert('Edit Failed');</script>";
          header("Location: ../manager_main.php");
        } else {
          header("Location:  ../manager_chains.php");
        }
      }
    }

    ?>