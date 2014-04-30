<?php

get_ip_from_file('212.txt','test1.txt');
get_ip_from_file2('212.txt','test2.txt');


	function get_ip_from_file($src_file,$out_file){
		$src_handle = @fopen("$src_file", "r");
		$fw = @fopen("$out_file",'w');
		if (!$src_handle){
		
		}
		if(!$fw){
		
		}
		//循环读取文件
		while (!feof($src_handle)) {
			//读取一行内容
			$buffer = fgets($src_handle, 1024);
			if($buffer !== false){
				//去除空白字符
				$buffer = trim($buffer);
				//正则匹配
				$pattern = '/(?:(?:25[0-5]|2[0-4]\d|((1\d{2})|([1-9]?\d)))\.){3}(?:25[0-5]|2[0-4]\d|((1\d{2})|([1-9]?\d)))/';
				preg_match($pattern, $buffer, $matches);
				if(isset($matches[0])){
					//写文件
					fwrite($fw,$matches[0]."\r\n");
				}else{
					//没有匹配到内容
				}
			}else{
				//读取错误。
			}
		}
		fclose($src_handle);
		fclose($fw);
	}
	
	function get_ip_from_file2($src_file,$out_file){
		$src_handle = @fopen("$src_file", "r");
		$fw = @fopen("$out_file",'w');
		if (!$src_handle){
		
		}
		if(!$fw){
		
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
					//写文件
					fwrite($fw,$ip."\r\n");
				}else{
					//没有匹配到内容
				}
			}else{
				//读取错误。
			}
		}
		fclose($src_handle);
		fclose($fw);
	}