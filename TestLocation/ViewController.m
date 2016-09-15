//
//  ViewController.m
//  TestLocation
//
//  Created by Bolu on 16/4/7.
//  Copyright © 2016年 Bolu. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "JZLocationConverter.h"

@interface ViewController () <CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *locationServiceStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationCityLabel;

@property(nonatomic,retain)CLLocationManager *locationManager;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self locate];
}




- (void)locate

{
    
    // 判断定位操作是否被允许
    
    if([CLLocationManager locationServicesEnabled]) {
        
        self.locationManager = [[CLLocationManager alloc] init] ;
        self.locationManager.delegate = self;
        self.locationManager.distanceFilter = kCLDistanceFilterNone;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        
    }else {
        
        //提示用户无法进行定位操作
        
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:
                                  
                                  @"提示" message:@"定位不成功 ,请确认开启定位" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        
        [alertView show];
        return;
        
    }
    
    // 开始定位
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    [self.locationManager startUpdatingLocation];

}


#pragma mark - CoreLocation Delegate

/** 定位服务状态改变时调用*/
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
        {
            NSLog(@"用户还未决定授权");
            break;
        }
        case kCLAuthorizationStatusRestricted:
        {
            NSLog(@"访问受限");
            break;
        }
        case kCLAuthorizationStatusDenied:
        {
            // 类方法，判断是否开启定位服务
            if ([CLLocationManager locationServicesEnabled]) {
                NSLog(@"定位服务开启，被拒绝");
            } else {
                NSLog(@"定位服务关闭，不可用");
            }
            break;
        }
        case kCLAuthorizationStatusAuthorizedAlways:
        {
            NSLog(@"获得前后台授权");
            break;
        }
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        {
            NSLog(@"获得前台授权");
            break;
        }
        default:
            break;
    }
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations

{
    self.locationServiceStatusLabel.text = @"开启";
    
    //此处locations存储了持续更新的位置坐标值，取最后一个值为最新位置，如果不想让其持续更新位置，则在此方法中获取到一个值之后让locationManager stopUpdatingLocation
    
    CLLocation *currentLocation = [locations lastObject];
    
    //iOS7,iOS8需要转换为火星坐标提高定位精准度(精确到建筑)
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 9.0) {
        //世界标准坐标转换成火星坐标
        CLLocationCoordinate2D converterCoordinate = [JZLocationConverter wgs84ToGcj02:currentLocation.coordinate];
        currentLocation = [[CLLocation alloc] initWithLatitude:converterCoordinate.latitude longitude:converterCoordinate.longitude];
    }
    
    // 获取当前所在的城市名
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    //根据经纬度反向地理编译出地址信息
    
    [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *array, NSError *error)
     
     {
         
         if (array.count > 0)
             
         {
             
             CLPlacemark *placemark = [array firstObject];
             
             
             
             //将获得的所有信息显示到label上
             
             NSLog(@"%@",placemark.name);
             
             //获取城市
             
             NSString *city = placemark.locality;
             
             if (!city) {
                 
                 //四大直辖市的城市信息无法通过locality获得，只能通过获取省份的方法来获得（如果city为空，则可知为直辖市）
                 
                 city = placemark.administrativeArea;
                 
             }
             
             self.locationCityLabel.text = [NSString stringWithFormat:@"定位城市:%@",city];
             
             NSLog(@"%@",city);
             
         }
         
         else if (error == nil && [array count] == 0)
             
         {
             
             NSLog(@"No results were returned.");
             
         }
         
         else if (error != nil)
             
         {
             
             NSLog(@"An error occurred = %@", error);
             
         }
         
     }];
    
    //系统会一直更新数据，直到选择停止更新，因为我们只需要获得一次经纬度即可，所以获取之后就停止更新
    
    [manager stopUpdatingLocation];
    self.locationServiceStatusLabel.text = @"关闭";
    
}

- (void)locationManager:(CLLocationManager *)manager

       didFailWithError:(NSError *)error {
    
    
    
    if (error.code == kCLErrorDenied) {
        
        // 提示用户出错原因，可按住Option键点击 KCLErrorDenied的查看更多出错信息，可打印error.code值查找原因所在
        
    }
    
}

@end
