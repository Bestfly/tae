/**
 * Created by Jericho.ou on 14-11-9.
 */

var LogUtil=require("../../util/LogUtil");
var URL=require("url");

var JDServiceGateBll={
    postData:function(request_url,headers,query,data,method,callback) {
        var SafeUtil=require("../../util/SafeUtil");
        var option={
            uri:request_url
            ,headers:headers
        };

        delete option.headers.host;

        option.headers.host=URL.parse(request_url).host;

        option.method=method;
        if(headers["content-type"].indexOf("x-www-form-urlencoded")>=0)
        {
            option.form=data;
        }
        else{
            option.body=data;
        }

        LogUtil.info(LogUtil.getLine());
        LogUtil.info("请求参数："+JSON.stringify(option));

        require('request')(option, function (error, response, body) {
            LogUtil.info(LogUtil.getLine());
            LogUtil.info("请求地址:"+option.uri);
            LogUtil.info("请求结果:"+((response==null || response.statusCode==null)?0:response.statusCode));
            LogUtil.info("内容:"+body);
            if(error){
                LogUtil.error("错误提示:"+error);
                body=error;
            }
            if(response.statusCode==200 && response.headers["content-type"].indexOf("/json")>=0 && body!=null){
                var JDDes3Key=require("../../config/MangoConfig").JDDes3Key
                response.headers["content-type"]="text/plain";
                try{
                    body=SafeUtil.DES3({
                        key: JDDes3Key,
                        plaintext: new String(body)
                    });
                    JDDes3Key=null;
                }
                catch(ex){
                    body="Server is Busy!";
                    response.statusCode=998;
                }
            }
            callback({
                data:body
                ,httpStatusCode:(response.statusCode==null?500:response.statusCode)
                ,contentType:response.headers["content-type"]
            });
        });
    }
};

module.exports = JDServiceGateBll;