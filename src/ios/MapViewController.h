//
//  MapViewController.h
//  AppointmentApp
//
//  Created by 林海波 on 2021/6/5.
//

#import <UIKit/UIKit.h>
#import <MAMapKit/MAMapKit.h>
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <AMapLocationKit/AMapLocationKit.h>

@interface MapViewController : UIViewController
-(instancetype)initWithLocation:(CLLocation *)location title:(NSString *)title subtitle:(NSString *)subtitle;
@end

