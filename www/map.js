const exec = require('cordova/exec');
const CDVAMap = {
    open_datepicker:function (success,option){
        exec(success,null,'CDVAMap','open_datepicker',[option]);
    },
    open_datetimepikcer:function (success,option){
        exec(success,null,'CDVAMap','open_datetimepikcer',[option]);
    },
    open_picker:function (success,option){
        exec(success,null,'CDVAMap','open_picker',[option]);
    },
    open_citypicker:function (success,option){
        exec(success,null,'CDVAMap','open_citypicker',[option]);
    }
};
module.exports = CDVAMap;
