#import <Cordova/CDV.h>
#import "CDVPicker.h"
#import <BRPickerView/BRPickerView.h>

@implementation CDVPicker
-(void)open_datepicker:(CDVInvokedUrlCommand *)command
{
    NSDictionary *options = [command.arguments objectAtIndex: 0];
    BRDatePickerView *datePickerView = [[BRDatePickerView alloc]init];
    datePickerView.pickerMode = BRDatePickerModeYMD;
    datePickerView.title = [options valueForKey:@"title"];
    NSString * select = [options valueForKey:@"select"];
    NSString * max_date = [options valueForKey:@"max"];
    NSString * min_date = [options valueForKey:@"min"];
    if(select) datePickerView.selectDate = [self dateFromString:select];
    if(min_date) datePickerView.minDate = [self dateFromString:min_date];
    if(max_date) datePickerView.maxDate = [self dateFromString:max_date];
    datePickerView.isAutoSelect = NO;
    datePickerView.resultBlock = ^(NSDate *selectDate, NSString *selectValue) {
        [self send_event:command withMessage:@{@"result":selectValue} Alive:NO State:YES];
    };
    [datePickerView show];
}
-(void)open_datetimepikcer:(CDVInvokedUrlCommand *)command
{
    NSDictionary *options = [command.arguments objectAtIndex: 0];
    BRDatePickerView *datePickerView = [[BRDatePickerView alloc]init];
    datePickerView.pickerMode = BRDatePickerModeYMDHM;
    datePickerView.title = [options valueForKey:@"title"];
    NSString * select = [options valueForKey:@"select"];
    NSString * max_date = [options valueForKey:@"max"];
    NSString * min_date = [options valueForKey:@"min"];
    if(select) datePickerView.selectDate = [self dateFromString:select];
    if(min_date) datePickerView.minDate = [self dateFromString:min_date];
    if(max_date) datePickerView.maxDate = [self dateFromString:max_date];
    datePickerView.isAutoSelect = NO;
    datePickerView.resultBlock = ^(NSDate *selectDate, NSString *selectValue) {
        [self send_event:command withMessage:@{@"result":selectValue} Alive:NO State:YES];
    };
    [datePickerView show];
}

-(void)open_picker:(CDVInvokedUrlCommand *)command
{
    NSDictionary *options = [command.arguments objectAtIndex: 0];
    BRStringPickerView *stringPickerView = [[BRStringPickerView alloc]init];
    stringPickerView.pickerMode = BRStringPickerComponentSingle;
    stringPickerView.title = [options valueForKey:@"title"];
    stringPickerView.dataSourceArr = [options valueForKey:@"list"];
    stringPickerView.selectValue = [options valueForKey:@"select"];
    stringPickerView.isAutoSelect = NO;
    stringPickerView.resultModelBlock = ^(BRResultModel *resultModel) {
        [self send_event:command withMessage:@{@"value":resultModel.value} Alive:NO State:YES];
    };
    [stringPickerView show];
}

-(void)open_citypicker:(CDVInvokedUrlCommand *)command
{
    NSDictionary *options = [command.arguments objectAtIndex: 0];
    BRAddressPickerView *addressPickerView = [[BRAddressPickerView alloc]init];
    BOOL onlycity = [[options valueForKey:@"onlycity"] boolValue] || NO;
    if(onlycity){
        addressPickerView.pickerMode = BRAddressPickerModeCity;
    }else{
        addressPickerView.pickerMode = BRAddressPickerModeArea;
    }
    addressPickerView.title = [options valueForKey:@"title"];
    NSString * city = [options valueForKey:@"city"];
    if(city){
        addressPickerView.selectValues = [city componentsSeparatedByString:@","];
    }
    addressPickerView.resultBlock = ^(BRProvinceModel *province, BRCityModel *city, BRAreaModel *area) {
        [self send_event:command withMessage:@{@"province": province.name, @"city": city.name , @"area" : area.name} Alive:NO State:YES];
    };

    [addressPickerView show];
}

#pragma mark 公共方法

- (void)send_event:(CDVInvokedUrlCommand *)command withMessage:(NSDictionary *)message Alive:(BOOL)alive State:(BOOL)state{
    if(!command) return;
    CDVPluginResult* res = [CDVPluginResult resultWithStatus: (state ? CDVCommandStatus_OK : CDVCommandStatus_ERROR) messageAsDictionary:message];
    if(alive) [res setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult: res callbackId: command.callbackId];
}
- (NSDate *) dateFromString:(NSString *)str
{
    NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy/MM/dd"];
    return [formatter dateFromString:str];
}

@end
