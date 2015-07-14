<?php 
$buf = 'int main(){printf("hello world"); return 0;}';
$tcc = tcc_new();
$ret = tcc_compile_string($tcc, $buf);
$ret = tcc_run($tcc);
?>
