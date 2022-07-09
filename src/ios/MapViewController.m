//
//  MapViewController.m
//  AppointmentApp
//
//  Created by 林海波 on 2021/6/5.
//

#import "MapViewController.h"
#import <MapKit/MapKit.h>
#import "UIViewController+HUD.h"
/** 设备的宽 */
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
/** 设备的高 */
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height


@interface MapViewController () <MAMapViewDelegate,AMapLocationManagerDelegate>
    @property (nonatomic, strong)MAMapView * mapView;
    @property (nonatomic, assign)CLLocationCoordinate2D currentLocationCoordinate;
    @property (nonatomic, strong)AMapLocationManager *locationManager;
    @property (nonatomic, strong)NSString * targetTitle;
@end

@implementation MapViewController

-(void) closemap{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(instancetype)initWithLocation:(CLLocation *)location title:(NSString *)title subtitle:(NSString *)subtitle
{
    self = [super init];
    if (self) {
        [MAMapView updatePrivacyShow:AMapPrivacyShowStatusDidShow privacyInfo:AMapPrivacyInfoStatusDidContain];
        [MAMapView updatePrivacyAgree:AMapPrivacyAgreeStatusDidAgree];
        CGFloat safeTop =  UIApplication.sharedApplication.keyWindow.safeAreaInsets.top;
        self.mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, safeTop + 44, SCREEN_WIDTH, SCREEN_HEIGHT)];
        self.mapView.delegate = self;
        self.mapView.mapType = MAMapTypeStandard;
        self.mapView.showsScale = NO;
        self.mapView.showsCompass = YES;
        self.mapView.showsUserLocation = NO;
        [self.view addSubview:self.mapView];
        self.currentLocationCoordinate = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude);
        [self showMapPoint];
        [self setCenterPoint];
        self.targetTitle = title;
        self.title = @"查看位置";
        CGFloat safeBottom =  UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        CGFloat BarHeight = 68.0 + safeBottom;
        UIView * infoView = [[UIView alloc] initWithFrame:CGRectMake(0.0, [UIScreen mainScreen].bounds.size.height - BarHeight , screenWidth, BarHeight)];
        infoView.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:infoView];
        
        UILabel * titleView = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, screenWidth, 30)];
        titleView.font = [UIFont boldSystemFontOfSize:15.0f];
        titleView.text = title;
        [infoView addSubview:titleView];
        
        UILabel * subtitleView = [[UILabel alloc] initWithFrame:CGRectMake(8,36, screenWidth, 30)];
        subtitleView.font = [UIFont systemFontOfSize:14.0f];
        subtitleView.text = subtitle;
        [infoView addSubview:subtitleView];
//        UIColor * c = [UIColor colorWithRed:255.0/255.0 green:88.0/255.0 blue:88.0/255.0 alpha:1];
//        UIButton * navBtn = [[UIButton alloc] initWithFrame:CGRectMake(screenWidth - 88, 18, 80, 30)];
//        [navBtn setTitleColor: c forState:UIControlStateNormal];
//        [navBtn setTitle:@"导航" forState:UIControlStateNormal];
//        navBtn.layer.cornerRadius = 15.0f;
//        navBtn.layer.borderWidth = 1.0f;
//        navBtn.layer.borderColor = c.CGColor;
//        [navBtn addTarget:self action:@selector(navmap:) forControlEvents:UIControlEventTouchUpInside];
//        [infoView addSubview:navBtn];
    }
    return self;
}

- (void)navmap
{
    self.locationManager = [[AMapLocationManager alloc] init];
    [self.locationManager setDelegate:self];
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
    //单次定位超时时间
    [self.locationManager setLocationTimeout:6];
    [self.locationManager setReGeocodeTimeout:3];
    
    [self showHudInView:self.view hint:@"正在定位..."];
    //带逆地理的单次定位
    [self.locationManager requestLocationWithReGeocode:YES completionBlock:^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error) {
        if (error) {
            [self showHint:@"定位错误，无法进行导航" yOffset:-180];
            [self hideHud];
            NSLog(@"locError:{%ld - %@};",(long)error.code,error.localizedDescription);
            if (error.code == AMapLocationErrorLocateFailed) {
                return ;
            }
        }
        [self hideHud];
        //定位信息
        NSDictionary *options = @{ MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving, MKLaunchOptionsMapTypeKey: [NSNumber numberWithInteger:MKMapTypeStandard], MKLaunchOptionsShowsTrafficKey:@YES };
        MKMapItem *startItem = [[MKMapItem alloc] initWithPlacemark: [[MKPlacemark alloc] initWithCoordinate:location.coordinate]];
        startItem.name = @"我的位置";
        MKMapItem *endItem = [[MKMapItem alloc] initWithPlacemark: [[MKPlacemark alloc] initWithCoordinate:self->_currentLocationCoordinate]];
        endItem.name = self.targetTitle;
        NSArray *items= @[startItem,endItem];
        [MKMapItem openMapsWithItems:items launchOptions:options];
    }];
}

- (void)showMapPoint{
    [_mapView setZoomLevel:15.1 animated:YES];
    [_mapView setCenterCoordinate:self.currentLocationCoordinate animated:YES];
}

- (void)setCenterPoint{
    MAPointAnnotation * centerAnnotation = [[MAPointAnnotation alloc] init];//初始化注解对象
    centerAnnotation.coordinate = self.currentLocationCoordinate;//定位经纬度
    [self.mapView addAnnotation:centerAnnotation];//添加注解
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIBarButtonItem * closeBtn = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStyleDone target:self action:@selector(closemap)];
    self.navigationItem.leftBarButtonItem = closeBtn;
    
    UIBarButtonItem * navBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"navigation"] style:UIBarButtonItemStylePlain target:self action:@selector(navmap)];
    self.navigationItem.rightBarButtonItem = navBtn;
}



@end
