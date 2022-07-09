//
//  ViewController.h
//  WeChatLocationDemo
//
//  Created by Lucas.Xu on 2017/12/8.
//  Copyright © 2017年 Lucas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MAMapKit/MAMapKit.h>
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <AMapLocationKit/AMapLocationKit.h>
#import <AMapSearchKit/AMapSearchKit.h>

typedef void(^CallBackBlock)(NSString *city,NSString *address,NSString *title,NSString * url,CGFloat lat,CGFloat lng);

@interface OpenMapViewController : UIViewController
    -(instancetype)initWithType:(NSString *)type;
    @property (nonatomic, copy) CallBackBlock callBackBlock;
    @property (nonatomic ,strong)AMapPOIAroundSearchRequest *request;
@end

