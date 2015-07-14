/**
 * Created by Jericho.ou on 15/6/17.
 */

function saveWebFlight() {
    require("./services/api/WebFlightBll").postData("qq12345","qiy","1234", "123","1","700",null, function (result) {
        if (result.error) {
            console.info(result.error);
        }
        else {
            console.info(result.data);
        }
    });
}

function getWebFlight() {
    require("./services/api/WebFlightBll").getDataSortByUK("qiy/1234", "123", function (result) {
        if (result.error) {
            console.info(result.error);
        }
        else {
            console.info(result.data);
        }
    });
}

setInterval(function(){
    saveWebFlight();
},10);

setInterval(function(){
    getWebFlight();
},10);
