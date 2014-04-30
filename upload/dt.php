<?php
$strtmp1=strval(rand(1,20));
$strtmp2=strval(rand(1,2));
echo str_pad($strtmp1,3,"0",STR_PAD_LEFT);
echo date("Ymd") . str_pad($strtmp2,3,"0",STR_PAD_LEFT);
?>
