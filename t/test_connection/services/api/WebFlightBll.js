/**
 * Created by Jericho.ou on 14-11-9.
 */

var request=require('request');

var LogUtil=require("../../util/LogUtil");

var FormatObjectUtil=require("../../util/FormatObjectUtil");

var WebFlightBll={
    postData:function(data,serviceName,queuesSecondName,uk,dt,sc,dataTypeExpiredDate,callback) {
        var apiConfig=require('../../config/BaseConfig').webFlight;
        var SafeUtil = require('../../util/SafeUtil');

        var apiKey = apiConfig.verifykey;
        var apiId=apiConfig.appidc01;
        var timestamp = parseInt(new Date().getTime() / 1000);
        var data = {
            "vb":data,
            "dt": parseInt("1"+dt),
            "sn": serviceName+":"+queuesSecondName,
            "sc": sc,
            "uk": uk
        };

        if(dataTypeExpiredDate){
            data.tl=parseInt(dataTypeExpiredDate);
        }

        if(data.dt.toString()!=="11"){
            delete data.sc;
        }

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
        option.headers['Auth-Appid']=apiId;
        option.headers['Auth-Signature'] = SafeUtil.MD5(apiKey+timestamp+apiId);
        option.headers['Content-Length'] = new Buffer(JSON.stringify(data)).length;

        var processApiTime=new Date().getTime();

        request(option, function (error, response, body) {
            var endProcessApiTime=new Date().getTime();
            var costTime=endProcessApiTime-processApiTime;
            if(costTime>=(60*1000)){
            }
            LogUtil.info(LogUtil.getLine());
            LogUtil.info("请求地址:"+option.uri);
            LogUtil.info("接口请求时间:"+FormatObjectUtil.dateFormat(processApiTime,"yyyy-MM-dd hh:mm:ss.S"));
            LogUtil.info("接口响应时间:"+FormatObjectUtil.dateFormat(endProcessApiTime,"yyyy-MM-dd hh:mm:ss.S"));
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
    ,getData:function(serviceName,queryString,soft,minPrice,maxPrice,callback){
        var apiConfig=require('../../config/BaseConfig').webFlight;
        var SafeUtil = require('../../util/SafeUtil');

        var apiKey = apiConfig.verifykey;
        var apiId=apiConfig.appidc01;
        var timestamp = parseInt(new Date().getTime() / 1000);
        var option={
            uri:apiConfig.getUrl+queryString
            ,headers:{}
        };
        option.method="GET";

        if(soft==="1"){
            if(minPrice!=null && maxPrice!=null){
                option.headers["If-Match"] = '['+minPrice+','+maxPrice+']';
            }
            else{
                option.headers["If-Match"] = 'sort';
            }
        }
        else{
            option.headers["If-Match"] = 'unsort';
        }

        option.headers["sn"]=serviceName;
        option.headers["accept"]="*/*";
        option.headers["Connection"]="Keep-Alive";
        option.headers['Auth-Appid']=apiId;
        option.headers['Auth-Timestamp'] = timestamp;
        option.headers['Auth-Signature'] = SafeUtil.MD5(apiKey+timestamp+apiId);

        var processApiTime=new Date().getTime();

        request(option, function (error, response, body) {
            var costTime=new Date().getTime()-processApiTime;
            //if(costTime>=(60*1000)){
            //
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
    ,delData:function(serviceName,soft,uk,callback){
        var apiConfig=require('../../config/BaseConfig').webFlight;
        var SafeUtil = require('../../util/SafeUtil');

        var apiKey = apiConfig.verifykey;
        var apiId=apiConfig.appidc01;
        var timestamp = parseInt(new Date().getTime() / 1000);
        var option={
            uri:apiConfig.delUrl+"/"+serviceName+"/"+uk
            ,headers:{}
        };
        option.method="DELETE";

        if(soft==="1"){
            option.headers["If-Match"] = 'sort';
        }
        else{
            option.headers["If-Match"] = 'unsort';
        }

        option.headers["accept"]="*/*";
        option.headers["Connection"]="Keep-Alive";
        option.headers['Auth-Appid']=apiId;
        option.headers['Auth-Timestamp'] = timestamp;
        option.headers['Auth-Signature'] = SafeUtil.MD5(apiKey+timestamp+apiId);

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
    ,getDataSortByUK:function(serviceName,uk,callback){
        var apiConfig=require('../../config/BaseConfig').webFlight;
        var SafeUtil = require('../../util/SafeUtil');

        var apiKey = apiConfig.verifykey;
        var apiId=apiConfig.appidc01;
        var timestamp = parseInt(new Date().getTime() / 1000);
        var option={
            uri:apiConfig.getSoftByUkUrl+"/"+serviceName+"/"+uk
            ,headers:{}
        };
        option.method="GET";

        option.headers["If-Match"] = 'sort';

        option.headers["accept"]="*/*";
        option.headers["Connection"]="Keep-Alive";
        option.headers['Auth-Appid']=apiId;
        option.headers['Auth-Timestamp'] = timestamp;
        option.headers['Auth-Signature'] = SafeUtil.MD5(apiKey+timestamp+apiId);

        var processApiTime=new Date().getTime();
        request(option, function (error, response, body) {
            var endProcessApiTime=new Date().getTime();
            var costTime=endProcessApiTime-processApiTime;
            //if(costTime>=(60*1000)){
            //}
            LogUtil.info(LogUtil.getLine());
            LogUtil.info("请求地址:"+option.uri);

            LogUtil.info("接口请求时间:"+FormatObjectUtil.dateFormat(processApiTime,"yyyy-MM-dd hh:mm:ss.S"));
            LogUtil.info("接口响应时间:"+FormatObjectUtil.dateFormat(endProcessApiTime,"yyyy-MM-dd hh:mm:ss.S"));
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

module.exports = WebFlightBll;

//WebFlightBll.getDataSortByUK("qiy/1234","123",function(result){
//    if(result.error){
//        console.info(result.error);
//    }
//    else{
//        console.info(result.data);
//    }
//});