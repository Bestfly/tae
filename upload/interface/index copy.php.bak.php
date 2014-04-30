<html>
<body>
<?php
/*
REQUEST :
Upload: aircanada.png
Type: image/png
path: /data/www/labs/cn100/0000000734
MD5 89bc81dd2879d2501a9e792830794a3d
Size: 368.943359375

_POST:
Name : aircanada.png
Type : image/png
Path : /data/www/labs/cn100/0000000734
MD5 : 89bc81dd2879d2501a9e792830794a3d
Size : 368.943359375Kb
*/
	echo "REQUEST :";
	echo "Upload: " . $_REQUEST["file_name"] . "";
	echo "Type: " . $_REQUEST["file_content_type"] . "";
	echo "path: " . $_REQUEST["file_path"] . "";
	echo "MD5 " . $_REQUEST["file_md5"] . "";
	echo "Size: " . ($_REQUEST["file_size"] / 1024) . "";

	echo "_POST:";
	echo "Name : " . $_POST["file_name"] . "";
	echo "Type : " . $_POST["file_content_type"] . "";
	echo "Path : " . $_POST["file_path"] . "";
	echo "MD5  : " . $_POST["file_md5"] . "";
	echo "Size : " . ($_POST["file_size"] / 1024) .  "Kb";

	function mkdirs($dir){
		if(!is_dir($dir)){
			if(!mkdirs(dirname($dir))){
				return false;
			}
			if(!mkdir($dir,0777)){
				return false;
			}
		}
		return true;
	}

	$temppath = $_POST["file_path"];
	$name = $_POST["file_name"];
	$md5 = $_POST["file_md5"];
	$f_dir = substr($md5,0,2);
	$s_dir = substr($md5,-2);
	$last_md5 = substr($md5,3,8);

	//mkdirs("/data/logs/labs/cn100/$f_dir/$s_dir");

	$catogory_name = substr($name,-3);
	//$catogory_name_last = strtoupper($catogory_name);
	$catogory_name_last = strtolower($catogory_name);
	$name_last = $last_md5.".".$catogory_name_last;

	$final_file_path = "/data/logs/labs/cn100/".$f_dir."/".$s_dir."/".$name_last;
	$simgurl = "http://labs.rhomobi.com/simg".$final_file_path;
	$srcurl = "http://labs.rhomobi.com/cn100imgs/".$f_dir.$s_dir.$name_last;
	$lit40url = $srcurl.".40x40.".$catogory_name_last;
	$lit80url = $srcurl.".80x80.".$catogory_name_last;
	$lit120url = $srcurl.".120x120.".$catogory_name_last;
	$file_content_type = $_POST["file_content_type"];

	/*
	echo $temppath."-";
	echo $name."-";
	echo $md5."-";
	echo $f_dir."-";
	echo $s_dir."-";
	echo $catogory_name_last."-";
	echo $name_last."-";
	echo $file_content_type;
	*/

	echo $simgurl;
	echo "<br />";
	echo $srcurl;
	echo "<br />";
	echo $lit40url;
	echo "<br />";
	echo $lit80url;
	echo "<br />";
	echo $lit120url;
	echo "<br />";
	//rename($temppath,$final_file_path);


	/*
	ob_start();
	system("/data/mongodb-linux-x86_64-2.0.6/bin/mongofiles put $final_file_path --host localhost --port 27017 --db simg -t $file_content_type");
	ob_end_clean();
	//----
	$mongoput = "/data/mongodb-linux-x86_64-2.0.6/bin/mongofiles put --host localhost --port 27017 --db simg $final_file_path";
	shell_exec($mongoput);
	echo $mongoput;
	*/
?>
<p>
	<img src=<?php echo $lit40url;?> alt=""/><br /><br />
	<img src=<?php echo $lit80url;?> alt=""/><br /><br />
	<img src=<?php echo $lit120url;?> alt=""/><br /><br />
</p>
</body>
</html>
