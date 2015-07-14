/**
 * Created by Administrator on 2014/10/10.
 */
var path = require('path');
var dirPath = path.join(__dirname, "../");

var BaseConfig = {
    logConfig: 0
    , serviceName: {
        "flight": {
            businessName: "FlightBll"
        },
        "tdsplus": {
            businessName: "CachedBll"
        },
        "tds": {
            businessName: "QueueBll"
        }
    }
    ,tdsPlusType:["queue","cacheQueue"]
    , webQueue: {
        pageSize: 1
        , postApiKey: '19958883-A3B8-4B67-93F3-F73F47B20340'
        , getApiKey: '5P826n55x3LkwK5k88S5b3XS4h30bTRb'
        , sid: "226998"
        , uid: "9953"
        , getUrl: 'http://api.cloudavh.com/task-rbs/'
        , postUrl: 'http://api.cloudavh.com/task-rbs'
        , queuesNameSecond: {
            "A0": "data"
        }
        , timeout: 15000
    }
    , webQueueAdvance: {
        pageSize: 2
        , postApiKey: '5P826n55x3LkwK5k88S5b3XS4h30bTRb'
        , getApiKey: '5P826n55x3LkwK5k88S5b3XS4h30bTRb'
        , sid: "226998"
        , uid: "9953"
        , getUrl: 'http://api.cloudavh.com/dbapi/'
        , postUrl: 'http://api.cloudavh.com/dbapi'
        , queuesNameSecond: {
            "A0": "data"
        }
        , timeout: 15000
    }
    ,webFlight:{
        appidc01:"142ffb5bfa1-cn-jijilu-dg-c01"
        ,appidc02:"142ffb5bfa1-cn-jijilu-dg-c02"
        , verifykey:"5P826n55x3LkwK5k88S5b3XS4h30bTRg"
        , getUrl:"http://api.cloudavh.com/tae"
        , postUrl:"http://api.cloudavh.com/tae"
        , delUrl:"http://api.cloudavh.com/del"
        , getSoftByUkUrl:"http://api.cloudavh.com/get"
    }
    ,logConfig:0,
    log4JSConfig: {
        "appenders": [
            {
                type: "console"
            }
            , {
                "type": "file",
                "filename": dirPath + "logs/debug/log.log",
                "maxLogSize": 3036000,
                "alwaysIncludePattern": false,
                "backups": 3,
                "category": "dev"
            },
            {
                "type": "file",
                "filename": dirPath + "logs/info/log.log",
                "maxLogSize": 3036000,
                "alwaysIncludePattern": false,
                "backups": 10,
                "category": "info"
            },
            {
                "type": "file",
                "filename": dirPath + "logs/error/log.log",
                "maxLogSize": 3036000,
                "alwaysIncludePattern": false,
                "backups": 10,
                "category": "error"
            }
        ]
        , replaceConsole: true
    }
};

module.exports = BaseConfig;