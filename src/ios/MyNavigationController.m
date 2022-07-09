//
//  MyNavigationController.m
//  LoveApp
//
//  Created by 林海波 on 2021/4/14.
//

#import "MyNavigationController.h"

@interface MyNavigationController ()

@end

@implementation MyNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor blackColor]};
    self.navigationBar.tintColor = [UIColor blackColor];
//    self.navigationBar.backgroundColor = [UIColor grayColor];
//    self.navigationBar.barStyle = UIBarStyleBlack;
    // Do any additional setup after loading the view.
}

- (BOOL)shouldAutorotate
{
    return NO;
}

//- (UIStatusBarStyle)preferredStatusBarStyle
//{
//    return UIStatusBarStyleLightContent;
//}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
