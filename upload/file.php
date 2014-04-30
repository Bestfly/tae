<?php
$ipkey= md5("pass".$_SERVER['REMOTE_ADDR']);
?>
<html>
<body>
<h2>Select files to upload</h2>
<form name="upload" enctype="multipart/form-data" action="/upload?key=<?php echo $ipkey;?>" method="post">
<input type="file" name="file"/><br />
<input type="submit" name="submit" value="Upload"/>
<input type="hidden" name="test" value="value"/>
</form>
</body>
</html>
