<?php

require_once './config/common.inc.php';
ini_set('memory_limit', '-1');
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
*/
	//function require_once对其无效
	function get_ip_from_file($src_file){
		$src_handle = @fopen("$src_file", "r");
		//$fw = @fopen("$out_file",'w');
		if (!$src_handle){
			die('ERROR: File can NOT be opened.');
		}
		//循环读取文件
		while (!feof($src_handle)) {
			//读取一行内容
			$buffer = fgets($src_handle, 1024);
			if($buffer !== false){
				//去除空白字符
				$buffer = trim($buffer);
				list($ip, $port) = explode(":", $buffer);
				if($ip){
					//写文件&Redis
					//fwrite($fw,$ip."\r\n");
					$count = $redis->lRem("rms:proxy", $ip.":".$port, 0);
					if ($count > 0){
						$redis->rPush("rms:proxy", $ip.":".$port);
						echo $ip.":".$port."-replace ok.<br />";
					}else{
						$redis->rPush("rms:proxy", $ip.":".$port);
						echo $ip.":".$port."-upload new.<br />";
					}
				}else{
					//没有匹配到内容
					echo 'ERROR: File can NOT be opened.';
				}
			}else{
				//读取错误。
				die('ERROR: File can NOT be read.');
			}
		}
		fclose($src_handle);
		//fclose($fw);
	}
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
	
	function extres($dir){
		$file_path = pathinfo($dir);
		if(!$file_path['extension']){
			return false;
		}else{
			return $file_path['extension'];
		}
	}
	/*
	$file_path = pathinfo('/www/htdocs/your_image.jpg'); 

	$file_path ['dirname'] //路径：/www/htdocs
	$file_path ['basename'] //文件名，包含扩展名：your_image.jpg
	$file_path ['extension'] //扩展名，如果没有则此项没有：jpg
	$file_path ['filename'] //文件名，不包含扩展名：your_image
	// only in PHP 5.2+ */
	
	$temppath = $_POST["file_path"];
	$name = $_POST["file_name"];
	$md5 = $_POST["file_md5"];
	$f_dir = substr($md5,0,2);
	$s_dir = substr($md5,-2);
	$last_md5 = substr($md5,3,-3);

	mkdirs("/data/logs/labs/cn100/$f_dir/$s_dir");

	//$catogory_name = substr($name,-3);
	//改为按照.获取文件后缀
	//list($filetname, $catogory_name) = explode(".", $name);
	$catogory_name = extres($name);
	//$catogory_name_last = strtoupper($catogory_name);
	$catogory_name_last = strtolower($catogory_name);
	$name_last = $last_md5.".".$catogory_name_last;

	$final_file_path = "/data/logs/labs/cn100/".$f_dir."/".$s_dir."/".$name_last;//文件实体
	
	//$simgurl = "http://labs.rhomobi.com/simg".$final_file_path;
	//$srcurl = "http://labs.rhomobi.com/cn100imgs/".$f_dir.$s_dir.$name_last;
	//$lit40url = $srcurl.".40x40.".$catogory_name_last;
	//$lit80url = $srcurl.".80x80.".$catogory_name_last;
	//$lit120url = $srcurl.".120x120.".$catogory_name_last;
	$file_content_type = $_POST["file_content_type"];

	rename($temppath,$final_file_path);
	//get_ip_from_file($final_file_path);
	$src_handle = @fopen($final_file_path, "r");
	//$fw = @fopen("$out_file",'w');
	if (!$src_handle){
		die('ERROR: File can NOT be opened.');
	}
	//循环读取文件
	while (!feof($src_handle)) {
		//读取一行内容
		$buffer = fgets($src_handle, 1024);
		if($buffer !== false){
			//去除空白字符
			$buffer = trim($buffer);
			list($ip, $port) = explode(":", $buffer);
			if($ip){
				//写文件&Redis
				//fwrite($fw,$ip."\r\n");
				$count = $redis->lRem("rms:proxy", $ip.":".$port, 0);
				if ($count > 0){
					$redis->rPush("rms:proxy", $ip.":".$port);
					echo $ip.":".$port."-replace ok.<br />";
				}else{
					$redis->rPush("rms:proxy", $ip.":".$port);
					echo $ip.":".$port."-upload new.<br />";
				}
			}else{
				//没有匹配到内容
				echo 'ERROR: File can NOT be opened.';
			}
		}else{
			//读取错误。
			die('ERROR: File can NOT be read.');
		}
	}
	fclose($src_handle);

	/*
	echo $temppath."<br />";
	echo $name."<br />";
	echo $md5."<br />";
	echo $f_dir."<br />";
	echo $s_dir."<br />";
	echo $catogory_name_last."<br />";
	echo $name_last."<br />";
	echo $final_file_path."<br />";
	echo $file_content_type."<br />";
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
	ob_start();
	system("/data/mongodb-linux-x86_64-2.0.6/bin/mongofiles put $final_file_path --host localhost --port 27017 --db simg -t $file_content_type");
	ob_end_clean();
	//----
	$mongoput = "/data/mongodb-linux-x86_64-2.0.6/bin/mongofiles put --host localhost --port 27017 --db simg $final_file_path";
	shell_exec($mongoput);
	echo $mongoput;
	*/
?>