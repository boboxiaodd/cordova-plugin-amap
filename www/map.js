const exec = require('cordova/exec');
const CDVAMap = {
    location:function (success){
        exec(success,null,'CDVAMap','location',[]);
    },
    showMap:function (success,option){
        exec(success,null,'CDVAMap','showMap',[option]);
    },
    openMap:function (success,option){
        exec(success,null,'CDVAMap','openMap',[option]);
    }
};
module.exports = CDVAMap;
