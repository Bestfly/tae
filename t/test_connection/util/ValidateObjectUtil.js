/**
 * Created by Jericho.ou on 15/1/5.
 */

module.exports={
  doValidate:function(user_data,rule){
    var rs="";
    for (var index in rule)
    {
      for(var i=0;i<rule[index].length;i++){
        var reg = new RegExp(rule[index][i][0]);
        if(!user_data[index] || !reg.test(user_data[index])){
          return rule[index][i][1];
        }
      }
    }
    return rs;
  }
};
