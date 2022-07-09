const exec = require('cordova/exec');
const CDVPicker = {
    open_datepicker:function (success,option){
        exec(success,null,'CDVPicker','open_datepicker',[option]);
    },
    open_datetimepikcer:function (success,option){
        exec(success,null,'CDVPicker','open_datetimepikcer',[option]);
    },
    open_picker:function (success,option){
        exec(success,null,'CDVPicker','open_picker',[option]);
    },
    open_citypicker:function (success,option){
        exec(success,null,'CDVPicker','open_citypicker',[option]);
    }
};
module.exports = CDVPicker;
