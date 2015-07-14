/**
 * Created by Jericho.ou on 14-11-9.
 */

var request=require('request');

var LogUtil=require("../../util/LogUtil");

var WebQueueAdvanceBll={
    postData:function(data,serviceName,queuesSecondName,uk,isQ,number,sc,callback) {
        var apiConfig=require('../../config/BaseConfig').webQueueAdvance;
        var SafeUtil = require('../../util/SafeUtil');

        var apiKey = apiConfig.postApiKey;
        var timestamp = parseInt(new Date().getTime() / 1000);
        var data = {
            "vb":data,
            "dt": number.toString()+isQ.toString(),
            "qn": serviceName+":"+queuesSecondName,
            "sc": sc,
            "uk":uk
        };

        if(data.sc==null){
            delete data.sc;
        }

        var option={
            uri:apiConfig.postUrl
            ,headers:{}
            ,time:true
        };
        option.method="POST";
        option.body=new Buffer(JSON.stringify(data));

        option.headers["Connection"]="Keep-Alive";
        option.headers['Auth-Timestamp'] = timestamp;
        option.headers['Auth-Signature'] = SafeUtil.MD5(apiKey+timestamp);
        option.headers['Content-Length'] = new Buffer(JSON.stringify(data)).length;

        var processApiTime=new Date().getTime();

        request(option, function (error, response, body) {
            var costTime=new Date().getTime()-processApiTime;
            //if(costTime>=(60*1000)){
            //}
            LogUtil.info(LogUtil.getLine());
            LogUtil.info("请求地址:"+option.uri);
            LogUtil.info("接口处理时间:"+costTime+"ms");
            LogUtil.info("请求头:"+JSON.stringify(option.headers));
            LogUtil.info("请求内容："+JSON.stringify(data));
            LogUtil.info("请求结果:"+((response==null || response.statusCode==null)?0:response.statusCode));
            LogUtil.info("内容:"+body);
            if(error){
                LogUtil.error(LogUtil.getLine());
                LogUtil.error("错误提示:"+error);
            }
            if(!error && response.statusCode!=200){
                error=response.statusCode;
            }
            callback({
                data:body
                ,error:error
            });
        });
    }
    ,getData:function(serviceName,queryString,callback){
        var apiConfig=require('../../config/BaseConfig').webQueueAdvance;
        var SafeUtil = require('../../util/SafeUtil');

        var apiKey = apiConfig.getApiKey;
        var timestamp = parseInt(new Date().getTime() / 1000);
        var option={
            uri:apiConfig.getUrl+serviceName+'/'+queryString
            ,headers:{}
        };
        option.method="GET";

        option.headers["accept"]="*/*";
        option.headers["Connection"]="Keep-Alive";
        option.headers['Auth-Timestamp'] = timestamp;
        option.headers['Auth-Signature'] = SafeUtil.MD5(apiKey+timestamp);

        var processApiTime=new Date().getTime();

        request(option, function (error, response, body) {
            var costTime=new Date().getTime()-processApiTime;
            //if(costTime>=(60*1000)){
            //}
            LogUtil.info(LogUtil.getLine());
            LogUtil.info("请求地址:"+option.uri);
            LogUtil.info("接口处理时间:"+costTime+"ms");
            LogUtil.info("请求头:"+JSON.stringify(option.headers));
            LogUtil.info("请求结果:"+((response==null || response.statusCode==null)?0:response.statusCode));
            LogUtil.info("内容:"+body);
            if(error){
                LogUtil.error(LogUtil.getLine());
                LogUtil.error("错误提示:"+error);
            }
            if(!error && response.statusCode!=200){
                error=response.statusCode;
            }
            callback({
                data:body
                ,error:error
            });
        });
    }
};

module.exports = WebQueueAdvanceBll;