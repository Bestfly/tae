/**
 * Created by user on 14-7-31.
 */

var FormatObjectUtil={
    getNowDateFormat:function(fmt) {
        var now_date = new Date();
        var o = {
            "M+": now_date.getMonth() + 1, //月份
            "d+": now_date.getDate(), //日
            "h+": now_date.getHours(), //小时
            "m+": now_date.getMinutes(), //分
            "s+": now_date.getSeconds(), //秒
            "q+": Math.floor((now_date.getMonth() + 3) / 3), //季度
            "S": now_date.getMilliseconds() //毫秒
        };
        if (/(y+)/.test(fmt)) fmt = fmt.replace(RegExp.$1, (now_date.getFullYear() + "").substr(4 - RegExp.$1.length));
        for (var k in o)
            if (new RegExp("(" + k + ")").test(fmt)) fmt = fmt.replace(RegExp.$1, (RegExp.$1.length == 1) ? (o[k]) : (("00" + o[k]).substr(("" + o[k]).length)));
        return fmt;
    }
    ,dateFormat:function(temp_data,fmt) {
        var now_date = new Date(temp_data);
        var o = {
            "M+": now_date.getMonth() + 1, //月份
            "d+": now_date.getDate(), //日
            "h+": now_date.getHours(), //小时
            "m+": now_date.getMinutes(), //分
            "s+": now_date.getSeconds(), //秒
            "q+": Math.floor((now_date.getMonth() + 3) / 3), //季度
            "S": now_date.getMilliseconds() //毫秒
        };
        if (/(y+)/.test(fmt)) fmt = fmt.replace(RegExp.$1, (now_date.getFullYear() + "").substr(4 - RegExp.$1.length));
        for (var k in o)
            if (new RegExp("(" + k + ")").test(fmt)) fmt = fmt.replace(RegExp.$1, (RegExp.$1.length == 1) ? (o[k]) : (("00" + o[k]).substr(("" + o[k]).length)));
        return fmt;
    }
    ,getRegArray:function(value,reg){
        var temp_array=[];
        var reg_exp=new RegExp(reg, "g");
        while ((temp_reg_result = reg_exp.exec(value)) != null)
        {
            temp_array[temp_array.length]=temp_reg_result[0].toString();
        }
        return temp_array;
    }
    ,unicode2string: function (str) {
        if (!str) return '';

        var r1 = /&#x([\d\w]{4};)/gi,
            r2 = /\\u([\d\w]{4})/gi,
            x;
        x = str.replace(r1, function (v) { return v.replace(/&#x/, '\\u').replace(';', '') })
            .replace(r2, function (m, g) { return String.fromCharCode(parseInt(g, 16)) });


        return unescape(x);
    }
};

module.exports = FormatObjectUtil;