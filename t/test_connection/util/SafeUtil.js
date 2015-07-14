/**
 * Created by user on 14-7-23.
 */

var SafeUtil = {
	MD5: function (str) {
		var md5sum = require('crypto').createHash('md5');
		md5sum.update(new Buffer(str));
		str = md5sum.digest('hex');
		return str;
	}
	,SHAR1:function(SecrectKey,content){
		var hash = require('crypto').createHmac('sha1', SecrectKey).update(content).digest();
		return (hash.toString('base64'));
	}
	,DES3:function(param){
		var assert = require('assert');
		var crypto = require('crypto');
		var iconv=require("iconv-lite");
		var key = new Buffer(param.key);
		var iv = new Buffer(param.iv ? param.iv : 0)
		var plaintext = iconv.toEncoding(param.plaintext, 'gbk');
		var alg = "des-ede3";
		var autoPad = true;
		if(key.length>24){
			key=key.slice(0,24);
		}
		var cipher = crypto.createCipheriv(alg, key, iv);
		cipher.setAutoPadding(autoPad)  //default true
		var ciph = cipher.update(plaintext, 'utf8', 'base64');
		ciph += cipher.final('base64');
		return ciph;
	}
};

module.exports = SafeUtil;