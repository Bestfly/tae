/**
 * Created by user on 14-7-24.
 */

var BaseConfig = require('../config/BaseConfig');
var log4js = require('log4js');
log4js.configure(BaseConfig.log4JSConfig, {});

var LogUtil = {
    dev: function (msg) {
        if (BaseConfig.logConfig <= 0) {
            log4js.getLogger("dev").info(msg);
        }
    }
    , info: function (msg) {
        if (BaseConfig.logConfig <= 1) {
            log4js.getLogger("info").info(msg);
        }
    }
    , product: function (msg) {
        if (BaseConfig.logConfig <= 2) {
            log4js.getLogger("info").info(msg);
        }
    }
    , error: function (msg) {
        if (BaseConfig.logConfig <= 3) {
            log4js.getLogger("error").info(msg);
        }
    }
    , getLine: function () {
        return ("------------------------------------------------------------------------------------------");
    }
};

module.exports = LogUtil;