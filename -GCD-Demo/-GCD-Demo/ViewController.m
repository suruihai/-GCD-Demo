//
//  ViewController.m
//  -GCD-Demo
//
//  Created by suruihai on 2017/1/5.
//  Copyright © 2017年 ruihai. All rights reserved.
//

#import "ViewController.h"
#import "SSNetworkTool.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 使用示例，在group success中可以把request1、request2、request3处理后的数据拼起来，这里就不提供使用效果，太麻烦了
    SSNetworkTool *tool = [SSNetworkTool sharedInstance];

    [tool sendGroupPostRequest:^{
        
        [tool sendPOSTRequest:@"request1" withData:@{} success:^(id responseObject) {
            // do something here
        } failure:^(NSError *error) {
            NSLog(@"%@", error);
        }];
        
        [tool sendPOSTRequest:@"request2" withData:@{} success:^(id responseObject) {
            // do something here
        } failure:^(NSError *error) {
            NSLog(@"%@", error);
        }];
        
        [tool sendPOSTRequest:@"request3" withData:@{} success:^(id responseObject) {
            // do something here
        } failure:^(NSError *error) {
            NSLog(@"%@", error);
        }];
        
    } success:^{
        // group success,
        // do something here
    } failure:^(NSArray *errorArray) {
        NSLog(@"%@", errorArray);
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
