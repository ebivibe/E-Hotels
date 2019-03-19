
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
<h1 class="title">Hotel Chain Edit</h1>
<?php

if ( ! empty( $_POST ) ) {
    if (  isset( $_POST['id'] ) ) {
        
        $query = 'Select * FROM public.HotelChain where chain_id='.$_POST['id'];
        $result = pg_query($query) ;
        $row = pg_fetch_row($result);
            echo "<form action=\"hotelchain_edit_request.php\" method=\"post\" class=\"loginform\" >
            <div class=\"form-group\">
            <label for=\"chain_id\">Chain_id:</label>
            <input type=\"text\" class=\"form-control\" name=\"chain_id\" placeholder=\"Chain Id\" value=".$row[0]." required readonly>
             </div>
            <div class=\"form-group\">
            <label for=\"chain_name\">Name:</label>
              <input type=\"text\" class=\"form-control\" name=\"chain_name\" placeholder=\"Name\" value=".$row[1]." required>
             </div>
             <div class=\"form-group\">
            <label for=\"chain_name\">Number of Hotels:</label>
              <input type=\"number\" class=\"form-control\" name=\"num_hotels\" placeholder=\"Number of Hotels\" value=".$row[2]." required readonly>
             </div>
             <div class=\"form-group\">
            <label for=\"chain_name\">Email:</label>
              <input type=\"text\" class=\"form-control\" name=\"email\" placeholder=\"Email\" value=".$row[3]." required>
             </div>
             <div class=\"form-group\">
             <label for=\"email\">Street Number:</label>
              <input type=\"number\" class=\"form-control\" name=\"streetnumber\" placeholder=\"Street Number\" value=".$row[4]." required>
            </div>
            <div class=\"form-group\">
            <label for=\"email\">Street Name:</label>
              <input type=\"text\" class=\"form-control\" name=\"streetname\" placeholder=\"Street Name\" value=".$row[5]." required>
            </div>
            <div class=\"form-group\">
            <label for=\"email\">Unit:</label>
              <input type=\"text\" class=\"form-control\" name=\"unit\" placeholder=\"Unit\" value=".$row[6]." >
             </div>
             <div class=\"form-group\">
             <label for=\"email\">City:</label>
             <input type=\"text\" class=\"form-control\" name=\"city\" placeholder=\"City\" value=".$row[7]." required>
             </div>
             <div class=\"form-group\">
             <label for=\"email\">Province:</label>
             <input type=\"text\" class=\"form-control\" name=\"province\" placeholder=\"Province\" value=".$row[8]." required>
            </div>
            <div class=\"form-group\">
            <label for=\"email\">Country:</label>
            <input type=\"text\" class=\"form-control\" name=\"country\" placeholder=\"Country\" value=".$row[9]." required>
            </div>
            <div class=\"form-group\">
            <label for=\"email\">Zip:</label>
            <input type=\"text\" class=\"form-control\" name=\"zip\" placeholder=\"Zip\" value=".$row[10]." required>
           </div>
            <button type=\"submit\" class=\"btn btn-primary\" value=\"Submit\">Submit</button>
          </form>
          <form action=\"\" method=\"post\" class=\"loginform\">
          <input type=\"text\" class=\"form-control\" name=\"chain_id\" placeholder=\"Chain Id\" value=".$row[0]." required hidden>
          <button type=\"submit\" class=\"btn btn-primary\" value=\"Submit\">Delete Chain</button>
          </form>";

    }
}

if ( ! empty( $_POST ) ) {
    if ( isset( $_POST["chain_id"] ) ) { 
        $query = 'delete from public.HotelChain where chain_id='.$_POST["chain_id"];
        $result = pg_query($query) ;
        print_r($query);
           
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
</center>



</body>
</html>