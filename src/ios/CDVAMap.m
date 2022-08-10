#import <Cordova/CDV.h>
#import "CDVAMap.h"
#import <AMapLocationKit/AMapLocationKit.h>
#import <AMapFoundationKit/AMapFoundationKit.h>
#import "MapNavigationController.h"
#import "OpenMapViewController.h"
#import "MapViewController.h"

@interface CDVAMap () <AMapLocationManagerDelegate>
@property (nonatomic,strong) AMapLocationManager *locationManager;
@property (nonatomic,readwrite) NSString * filepath;
@end

@implementation CDVAMap

- (void)amapLocationManager:(AMapLocationManager *)manager doRequireLocationAuth:(CLLocationManager *)locationManager
{
    [locationManager requestAlwaysAuthorization];
}

-(void)pluginInitialize
{
    [AMapServices sharedServices].apiKey = [self settingForKey:@"amap.key"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *directoryPaths = [fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask];
    NSURL *distPath = [[directoryPaths firstObject] URLByAppendingPathComponent:@"NoCloud/www/www"];
    _filepath = [distPath path];
}
- (void)location:(CDVInvokedUrlCommand *)command{
    [AMapLocationManager updatePrivacyAgree:AMapPrivacyAgreeStatusDidAgree];
    [AMapLocationManager updatePrivacyShow:AMapPrivacyShowStatusDidShow privacyInfo:AMapPrivacyInfoStatusDidContain];
    _locationManager = [[AMapLocationManager alloc] init];
    _locationManager.delegate = self;
    [_locationManager setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
    //单次定位超时时间
    [_locationManager setLocationTimeout:6];
    [_locationManager setReGeocodeTimeout:3];
    [_locationManager requestLocationWithReGeocode:YES completionBlock:^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error) {
        NSLog(@"requestLocationWithReGeocode:xxxxxxxxxxxxx");
        if (error) {
            if (error.code == AMapLocationErrorLocateFailed) {
                [self send_event:command withMessage:@{@"result":@"fail",@"code": @(error.code)} Alive:NO State:YES];
                return ;
            }
            if (error.code == AMapLocationErrorReGeocodeFailed) {
                [self send_event:command withMessage:@{@"result":@"success",
                                                       @"lat":[NSString stringWithFormat:@"%g",location.coordinate.latitude],
                                                       @"lng":[NSString stringWithFormat:@"%g",location.coordinate.longitude],
                                                       @"city": @"未知城市" } Alive:NO State:YES];
            }
        }else{
            NSString *city = @"";
            if (regeocode)
            {
                city = regeocode.city;
            }
            [self send_event:command withMessage:@{@"result":@"success",
                                                   @"lat":[NSString stringWithFormat:@"%g",location.coordinate.latitude],
                                                   @"lng":[NSString stringWithFormat:@"%g",location.coordinate.longitude],
                                                   @"city": city } Alive:NO State:YES];
        }
    }];

}
- (void)showMap:(CDVInvokedUrlCommand *)command{
    NSDictionary *options = [command.arguments objectAtIndex: 0];
    CLLocation * location = [[CLLocation alloc] initWithLatitude:[[options valueForKey:@"lat"] floatValue] longitude:[[options valueForKey:@"lng"] floatValue]];
    MapViewController * vc = [[MapViewController alloc] initWithLocation:location title:[options valueForKey:@"title"] subtitle:[options valueForKey:@"subtitle"]];
    MapNavigationController *nc = [[MapNavigationController alloc] initWithRootViewController:vc];
    nc.modalPresentationStyle = UIModalPresentationFullScreen;
    nc.view.backgroundColor = [UIColor whiteColor];
    [self.viewController presentViewController:nc animated:YES completion:nil];
}
- (void)openMap:(CDVInvokedUrlCommand *)command{
    NSDictionary *options = [command.arguments objectAtIndex: 0];
    NSString * iconpath = [NSString stringWithFormat:@"%@%@",_filepath,[options valueForKey:@"icon"]];
    OpenMapViewController * vc = [[OpenMapViewController alloc] initWithType:[options valueForKey:@"type"] withIcon:iconpath];
    vc.callBackBlock = ^(NSString *city,NSString *address,NSString * title, NSString * url, CGFloat lat, CGFloat lng) {
        [self send_event:command withMessage:@{
            @"name":title,
            @"address":address,
            @"url": url,
            @"city": city,
            @"lat": [NSString stringWithFormat:@"%g",lat],
            @"lng": [NSString stringWithFormat:@"%g",lng]
        } Alive:NO State:YES];
    };
    MapNavigationController *nc = [[MapNavigationController alloc] initWithRootViewController:vc];
    nc.view.backgroundColor = [UIColor whiteColor];
    nc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.viewController presentViewController:nc animated:YES completion:^{

    }];
}
#pragma mark 公共方法

- (void)send_event:(CDVInvokedUrlCommand *)command withMessage:(NSDictionary *)message Alive:(BOOL)alive State:(BOOL)state{
    if(!command) return;
    CDVPluginResult* res = [CDVPluginResult resultWithStatus: (state ? CDVCommandStatus_OK : CDVCommandStatus_ERROR) messageAsDictionary:message];
    if(alive) [res setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult: res callbackId: command.callbackId];
}
- (id)settingForKey:(NSString*)key
{
    return [self.commandDelegate.settings objectForKey:[key lowercaseString]];
}
@end
