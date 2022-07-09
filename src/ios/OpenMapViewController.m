//
//  ViewController.m
//  WeChatLocationDemo
//
//  Created by Lucas.Xu on 2017/12/8.
//  Copyright © 2017年 Lucas. All rights reserved.
//

#import "OpenMapViewController.h"
#import <UIKit/UIKit.h>
#import "POITableViewCell.h"
#import "MJRefresh.h"
#import "UIViewController+HUD.h"

/** 设备的宽 */
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
/** 设备的高 */
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface OpenMapViewController ()<UISearchControllerDelegate,UISearchResultsUpdating,MAMapViewDelegate,AMapLocationManagerDelegate,AMapSearchDelegate,UITableViewDelegate,UITableViewDataSource>
@property (nonatomic, strong)UISearchController *searchController;
@property (nonatomic, assign)CLLocationCoordinate2D currentLocationCoordinate;
@property (nonatomic, strong)MAMapView * mapView;
@property (nonatomic, strong)AMapLocationManager *locationManager;
@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic,strong)AMapSearchAPI *mapSearch;
@property (nonatomic,strong)NSArray *dataArray;
@property (nonatomic ,assign)NSInteger currentPage;
@property (nonatomic ,assign)BOOL isSelectedAddress;
@property (nonatomic ,strong)NSIndexPath *selectedIndexPath;
@property (nonatomic ,strong)NSString *city;//定位的当前城市，用于搜索功能

@property (nonatomic ,strong)UITableView *searchTableView;//用于搜索的tableView
@property (nonatomic ,strong)NSArray *tipsArray;//搜索提示的数组
@property (nonatomic ,strong)NSMutableArray *remoteArray;
@property (nonatomic ,strong)AMapPOI *currentPOI;//点击选择的当前的位置插入到数组中
@property (nonatomic ,assign)BOOL isClickPoi;

@property (nonatomic, strong)UIButton * localButton;


@end

@implementation OpenMapViewController

- (UIImage *)imageFromView:(UIView *)view
{
    UIScreen *screen = [UIScreen mainScreen];
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, screen.scale);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

-(void) closemap
{
    if(self.dataArray.count > 0){
        [_localButton removeFromSuperview];
        self.mapView.showsUserLocation = NO;
        self.mapView.showsCompass = NO;
        [self showHudInView:self.view hint:@"请稍候..."];
        [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:NO block:^(NSTimer * _Nonnull timer) {
            UIImage * resultImage = [self imageFromView:self.mapView];
            NSData *imageData = UIImageJPEGRepresentation(resultImage,0.8);
            NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
            NSURL *fileURL = [[tmpDirURL URLByAppendingPathComponent:[[NSUUID UUID] UUIDString]] URLByAppendingPathExtension:@"jpg"];
            [imageData writeToURL:fileURL atomically:YES];
            imageData = nil;
            AMapPOI *POIModel = self.dataArray[self.selectedIndexPath.row];
            self.callBackBlock(POIModel.city,
                               POIModel.address,
                               POIModel.name,
                               [fileURL path] ,
                               POIModel.location.latitude,
                               POIModel.location.longitude);
            [self hideHud];
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
    }else{
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}
-(void) cancelmap{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (instancetype)initWithType:(NSString *)type
{
    self = [super init];
    if (self) {
        self.isSelectedAddress = true;
        self.request = [[AMapPOIAroundSearchRequest alloc] init];
        self.request.keywords  = type;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"位置";
    [self setUpSearchController];
    UIBarButtonItem * closeBtn = [[UIBarButtonItem alloc] initWithTitle:@"确定" style:UIBarButtonItemStyleDone target:self action:@selector(closemap)];
    self.navigationItem.rightBarButtonItem = closeBtn;

    UIBarButtonItem * cancelBtn = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStyleDone target:self action:@selector(cancelmap)];
    self.navigationItem.leftBarButtonItem = cancelBtn;

    self.currentPage = 1;
    [self initMapView];
    [self.view addSubview:self.tableView];
    [self configLocationManager];
    [self locateAction];
    self.remoteArray = @[].mutableCopy;
    self.mapSearch = [[AMapSearchAPI alloc] init];
    self.mapSearch.delegate = self;

    /* 按照距离排序. */
    self.request.sortrule = 0;
    self.request.offset = 50;
    self.request.requireExtension = YES;
    self.selectedIndexPath=[NSIndexPath indexPathForRow:-1 inSection:-1];
}

- (void)setUpSearchController{
//    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
//    self.searchController.delegate = self;
//    self.searchController.searchResultsUpdater = self;
//    self.searchController.dimsBackgroundDuringPresentation = NO;
//    self.searchController.definesPresentationContext = YES;
//    UISearchBar *bar = self.searchController.searchBar;
//    CGFloat safeTop =  UIApplication.sharedApplication.keyWindow.safeAreaInsets.top;
//    bar.frame = CGRectMake(0, safeTop + 44, SCREEN_WIDTH, 44);
//    bar.backgroundColor = [UIColor blackColor];
//    bar.barTintColor = [UIColor blackColor];//[UIColor groupTableViewBackgroundColor];
//    UITextField *searchField = [bar valueForKey:@"searchField"];
//    searchField.placeholder = @"搜索地点";
//    searchField.textColor = [UIColor whiteColor];
//    [bar setTintColor:[UIColor whiteColor]];
//    [bar setValue:@"取消" forKey:@"cancelButtonText"];
//
//    [self.view addSubview:bar];
}

- (void)initMapView{
    [MAMapView updatePrivacyShow:AMapPrivacyShowStatusDidShow privacyInfo:AMapPrivacyInfoStatusDidContain];
    [MAMapView updatePrivacyAgree:AMapPrivacyAgreeStatusDidAgree];
    CGFloat safeTop =  UIApplication.sharedApplication.keyWindow.safeAreaInsets.top;
    self.mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, safeTop + 44, SCREEN_WIDTH, 344)];
    self.mapView.delegate = self;
    self.mapView.mapType = MAMapTypeBus;
    self.mapView.showsScale = YES;
    self.mapView.showsCompass = YES;
    self.mapView.showsUserLocation = YES;
    [self.view addSubview:self.mapView];

    _localButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    _localButton.backgroundColor = [UIColor redColor];
    _localButton.frame = CGRectMake(SCREEN_WIDTH - 60, 244, 50, 50);
    [_localButton addTarget:self action:@selector(localButtonAction) forControlEvents:UIControlEventTouchUpInside];
//    _localButton.layer.cornerRadius = 25;
//    _localButton.clipsToBounds = YES;
    [_localButton setImage:[UIImage imageNamed:@"ic-my-location"] forState:UIControlStateNormal];
    [self.mapView addSubview:_localButton];

}

- (UITableView *)tableView{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 408, SCREEN_WIDTH, SCREEN_HEIGHT - 408) style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.tableFooterView = [UIView new];
        self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
            self.currentPage ++ ;
            self.request.page = self.currentPage;
            self.request.location = [AMapGeoPoint locationWithLatitude:self.currentLocationCoordinate.latitude longitude:self.currentLocationCoordinate.longitude];
            [self.mapSearch AMapPOIAroundSearch:self.request];
        }];
    }
    return _tableView;
}

- (UITableView *)searchTableView{
    if (_searchTableView == nil) {
        CGFloat safeTop =  UIApplication.sharedApplication.keyWindow.safeAreaInsets.top;
        _searchTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 54 + safeTop, SCREEN_WIDTH, SCREEN_HEIGHT - 54 - safeTop) style:UITableViewStylePlain];
        _searchTableView.delegate = self;
        _searchTableView.dataSource = self;
//        _searchTableView.backgroundColor = [UIColor blackColor];
        _searchTableView.tableFooterView = [UIView new];
    }
    return _searchTableView;
}

// 定位SDK
- (void)configLocationManager {
    self.locationManager = [[AMapLocationManager alloc] init];
    [self.locationManager setDelegate:self];
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
    //单次定位超时时间
    [self.locationManager setLocationTimeout:6];
    [self.locationManager setReGeocodeTimeout:3];
}

- (void)locateAction {
    [self showHudInView:self.view hint:@"正在定位..."];
    //带逆地理的单次定位
    [self.locationManager requestLocationWithReGeocode:YES completionBlock:^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error) {
        if (error) {
            [self showHint:@"定位错误" yOffset:-180];
            [self hideHud];
            NSLog(@"locError:{%ld - %@};",(long)error.code,error.localizedDescription);
            if (error.code == AMapLocationErrorLocateFailed) {
                return ;
            }
        }
        //定位信息
        NSLog(@"location:%@", location);
        if (regeocode)
        {
            [self hideHud];
            self.isClickPoi = NO;
            self.currentLocationCoordinate = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude);
            self.city = regeocode.city;
            [self showMapPoint];
            [self setCenterPoint];
            self.request.location = [AMapGeoPoint locationWithLatitude:location.coordinate.latitude longitude:location.coordinate.longitude];
//            self.request.city = regeocode.city;
            [self.mapSearch AMapPOIAroundSearch:self.request];
        }else{
            [self hideHud];
            self.request.location = [AMapGeoPoint locationWithLatitude:location.coordinate.latitude longitude:location.coordinate.longitude];
            self.request.city = regeocode.city;
            [self showHint:@"无法使用搜索功能" yOffset:-180];
        }
    }];

}

- (void)showMapPoint{
    [_mapView setZoomLevel:15.1 animated:YES];
    [_mapView setCenterCoordinate:self.currentLocationCoordinate animated:YES];
}

- (void)setCenterPoint{
    MAPointAnnotation * centerAnnotation = [[MAPointAnnotation alloc] init];//初始化注解对象
    centerAnnotation.coordinate = self.currentLocationCoordinate;//定位经纬度
    centerAnnotation.title = @"";
    centerAnnotation.subtitle = @"";
    [self.mapView addAnnotation:centerAnnotation];//添加注解

}


#pragma mark - MAMapView Delegate
- (MAAnnotationView *)mapView:(MAMapView *)mapView
            viewForAnnotation:(id<MAAnnotation>)annotation {
    if ([annotation isKindOfClass:[MAPointAnnotation class]]) {
        static NSString *pointReuseIndentifier = @"pointReuseIndentifier";
        MAPinAnnotationView*annotationView = (MAPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndentifier];
        if (annotationView == nil)
        {
            annotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pointReuseIndentifier];
        }
        annotationView.canShowCallout= YES;       //设置气泡可以弹出，默认为NO
        annotationView.animatesDrop = YES;        //设置标注动画显示，默认为NO
        annotationView.draggable = YES;        //设置标注可以拖动，默认为NO
        annotationView.pinColor = MAPinAnnotationColorRed;
        return annotationView;
    }
    return nil;
}


- (void)mapView:(MAMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    [self.mapView removeAnnotations:self.mapView.annotations];

    CLLocationCoordinate2D centerCoordinate = mapView.region.center;
    self.currentLocationCoordinate = centerCoordinate;

    MAPointAnnotation * centerAnnotation = [[MAPointAnnotation alloc] init];
    centerAnnotation.coordinate = centerCoordinate;
    centerAnnotation.title = @"";
    centerAnnotation.subtitle = @"";
    [self.mapView addAnnotation:centerAnnotation];
    //主动选择地图上的地点
    if (!self.isSelectedAddress) {
        self.isClickPoi = NO;
        [self.tableView setContentOffset:CGPointMake(0,0) animated:NO];
        self.selectedIndexPath=[NSIndexPath indexPathForRow:0 inSection:0];
        self.request.location = [AMapGeoPoint locationWithLatitude:centerCoordinate.latitude longitude:centerCoordinate.longitude];
        self.currentPage = 1;
        self.request.page = self.currentPage;
        [self.mapSearch AMapPOIAroundSearch:self.request];
    }
    self.isSelectedAddress = NO;

}


#pragma mark -AMapSearchDelegate
- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response{
    NSMutableArray *remoteArray = response.pois.mutableCopy;
    self.remoteArray = remoteArray;
    if (self.isClickPoi) {
        [remoteArray insertObject:self.currentPOI atIndex:0];
    }
    if (self.currentPage == 1) {
        self.dataArray = remoteArray;
    }else{
        NSMutableArray * moreArray = self.dataArray.mutableCopy;
        [moreArray addObjectsFromArray:remoteArray];
        self.dataArray = moreArray.copy;
    }

    if (response.pois.count< 50) {
        [self.tableView.mj_footer endRefreshingWithNoMoreData];
    }else{
        [self.tableView.mj_footer endRefreshing];
    }
    [self.tableView reloadData];


}

- (void)onInputTipsSearchDone:(AMapInputTipsSearchRequest *)request response:(AMapInputTipsSearchResponse *)response{

    self.tipsArray = response.tips;
    [self.searchTableView reloadData];

}

#pragma mark - UITableViewDelegate && UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (tableView == self.tableView) {
        return self.dataArray.count;
    }else{
        return self.tipsArray.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellID = @"POITableViewCell";
    POITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:cellID owner:nil options:nil] firstObject];
    }
    if (tableView == self.tableView) {
        AMapPOI *POIModel = self.dataArray[indexPath.row];
        cell.nameLabel.text = POIModel.name;
        cell.addressLable.text = POIModel.address;
        if (indexPath.row==self.selectedIndexPath.row){
            cell.accessoryType=UITableViewCellAccessoryCheckmark;
        }else{
            cell.accessoryType=UITableViewCellAccessoryNone;
        }
    }else{
        AMapTip *tipModel = self.tipsArray[indexPath.row];
        cell.nameLabel.text = tipModel.name;
        cell.addressLable.text = tipModel.address;

    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.tableView == tableView) {
        self.selectedIndexPath=indexPath;
        [tableView reloadData];
        AMapPOI *POIModel = self.dataArray[indexPath.row];
        CLLocationCoordinate2D locationCoordinate = CLLocationCoordinate2DMake(POIModel.location.latitude, POIModel.location.longitude);
        [_mapView setCenterCoordinate:locationCoordinate animated:YES];
        self.isSelectedAddress = YES;
    }else{
        self.searchController.active = NO;
        [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
        AMapTip *tipModel = self.tipsArray[indexPath.row];
        CLLocationCoordinate2D locationCoordinate = CLLocationCoordinate2DMake(tipModel.location.latitude, tipModel.location.longitude);
        [_mapView setCenterCoordinate:locationCoordinate animated:YES];
        self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView reloadData];

        AMapPOI *POIModel = [AMapPOI new];
        POIModel.address = [NSString stringWithFormat:@"%@%@",tipModel.district,tipModel.address];
        POIModel.location = tipModel.location;
        POIModel.name = tipModel.name;
        self.currentPOI = POIModel;
        self.isClickPoi = YES;
        [self.tableView reloadData];


    }


}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    if (scrollView == self.searchTableView) {
        [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    }
}




#pragma mark - UISearchControllerDelegate && UISearchResultsUpdating

//谓词搜索过滤
-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    if (searchController.searchBar.text.length == 0) {
        return;
    }
    [self.view addSubview:self.searchTableView];
    AMapInputTipsSearchRequest *tips = [[AMapInputTipsSearchRequest alloc] init];
    tips.keywords = searchController.searchBar.text;
    tips.city = self.city;
    [self.mapSearch AMapInputTipsSearch:tips];

}


#pragma mark - UISearchControllerDelegate代理
- (void)willPresentSearchController:(UISearchController *)searchController{
//    CGFloat safeTop =  UIApplication.sharedApplication.keyWindow.safeAreaInsets.top;
    self.searchController.searchBar.frame = CGRectMake(0, 0, self.searchController.searchBar.frame.size.width, 44.0);
//    self.mapView.frame = CGRectMake(0, safeTop + 44, SCREEN_WIDTH, 300);
    self.tableView.frame = CGRectMake(0, 364, SCREEN_WIDTH, SCREEN_HEIGHT - 364);
    NSLog(@"ss---%@",NSStringFromCGRect(self.tableView.frame));

}

- (void)didDismissSearchController:(UISearchController *)searchController{
    CGFloat safeTop =  UIApplication.sharedApplication.keyWindow.safeAreaInsets.top;
    self.searchController.searchBar.frame = CGRectMake(0, safeTop + 44, self.searchController.searchBar.frame.size.width, 44.0);
//    self.mapView.frame = CGRectMake(0, safeTop + 88, SCREEN_WIDTH, 300);
    self.tableView.frame = CGRectMake(0, 408, SCREEN_WIDTH, SCREEN_HEIGHT - 408);
//    [searchController.searchBar sizeToFit];
    [self.searchTableView removeFromSuperview];
}



- (void)localButtonAction{
    [self locateAction];
}





@end
