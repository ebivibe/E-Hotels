
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
if ( ! empty( $_POST ) ) {
    if ( isset( $_POST["chain_id"] ) ) { 
        $query = 'update public.HotelChain set chain_name=\''.$_POST['chain_name'].'\', email=\''.$_POST['email'].'\',
        street_number=\''.$_POST['streetnumber'].'\',
        street_name=\''.$_POST['streetname'].'\',  unit=\''.$_POST['unit'].'\',  city=\''.$_POST['city'].'\',
        province=\''.$_POST['province'].'\',   country=\''.$_POST['country'].'\',  zip=\''.$_POST['zip'].'\'
        where chain_id='.$_POST['chain_id'];
        print_r($query);
        $result = pg_query($query) ;
        print_r($result);
        
        //exit;
           
      if(!$result){
        echo "<script>alert('Edit Failed');</script>";
        header("Location: ../manager_chains.php");
      } else{
        echo "<script>alert('Edit Success');</script>";
        header("Location: ../manager_chains.php");
      }
    }
}


?>
</body>
</html>