//
//  SSNetworkTool.h
//  -GCD-Demo
//
//  Created by suruihai on 2017/1/5.
//  Copyright © 2017年 ruihai. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^BlockAction)();
typedef void(^BlockResponse)(id responseObject);
typedef void(^BlockResponseFailure)(NSError * error);
typedef void(^GroupResponseFailure)(NSArray * errorArray);

@interface SSNetworkTool : NSObject

- (void)sendPOSTRequest:(NSString *)strURL withData:(NSDictionary *)data success:(BlockResponse)success failure:(BlockResponseFailure)failure;
- (void)sendPOSTRequest:(NSString *)strURL withData:(NSDictionary *)data withTimeout:(NSTimeInterval)timeout showAlert:(BOOL)show  success:(BlockResponse)success failure:(BlockResponseFailure)failure;

/**
 *  并发组请求
 *
 *  @param requests 并发的请求，block中正常执行请求操作
 *  @param success  全部请求success后执行
 *  @param failure  只要有一个请求failure后执行
 */
- (void)sendGroupPostRequest:(BlockAction)requests success:(BlockAction)success failure:(GroupResponseFailure)failure;

+ (instancetype)sharedInstance;
@end
