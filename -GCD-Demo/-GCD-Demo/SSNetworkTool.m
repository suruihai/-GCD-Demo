//
//  SSNetworkTool.m
//  -GCD-Demo
//
//  Created by suruihai on 2017/1/5.
//  Copyright © 2017年 ruihai. All rights reserved.
//

#import <objc/runtime.h>
#import "SSNetworkTool.h"
#import "AFNetworking.h"

static char groupErrorKey;
static char queueGroupKey;

@interface SSNetworkTool()
@property (strong, nonatomic) AFHTTPSessionManager *sessionManager;
@end

@implementation SSNetworkTool

+ (instancetype)sharedInstance {
    
    static id obj = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[self alloc] init];
    });
    return obj;
}

- (AFHTTPSessionManager *)sessionManager {
    if (_sessionManager == nil) {
        _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@""] sessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/plain", @"text/html", @"multipart/form-data", @"image/webp", @"*/*", @"application/xml", @"application/xhtml+xml", nil];
    }
    return _sessionManager;
}


- (void)sendPOSTRequest:(NSString *)strURL withData:(NSDictionary *)data success:(BlockResponse)success failure:(BlockResponseFailure)failure {
    [self sendPOSTRequest:strURL withData:data withTimeout:30.0 showAlert:NO success:success failure:failure];
}

/**
 THE VERY BASE METHOD
 */
- (void)sendPOSTRequest:(NSString *)strURL withData:(NSDictionary *)data withTimeout:(NSTimeInterval)timeout showAlert:(BOOL)show  success:(BlockResponse)success failure:(BlockResponseFailure)failure {
    NSDictionary *param = data;
    self.sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    self.sessionManager.requestSerializer.timeoutInterval = timeout;
    [self.sessionManager POST:[[NSURL URLWithString:strURL relativeToURL:self.sessionManager.baseURL] absoluteString] parameters:param success:^(NSURLSessionDataTask *task, id responseObject) {
        
        NSLog(@"\nsend:%@\npost:%@\nsucess: %@", strURL, param, responseObject);
        
        if (success) {
            success(responseObject);
        }
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        if (failure) {
            failure(error);
        }
        
    }];
}

- (void)sendPOSTRequestInGroup:(NSString *)strURL withData:(NSDictionary *)data withTimeout:(NSTimeInterval)timeout showAlert:(BOOL)show  success:(BlockResponse)success failure:(BlockResponseFailure)failure {
    
    dispatch_group_t group = objc_getAssociatedObject([NSOperationQueue currentQueue], &queueGroupKey);
    
    // 如果是非组请求
    if (group == nil) {
        // 执行original method
        [self sendPOSTRequestInGroup:strURL withData:data withTimeout:timeout showAlert:show success:success failure:failure];
        return;
    }
    
    dispatch_group_enter(group);
    // 执行original method
    [self sendPOSTRequestInGroup:strURL withData:data withTimeout:timeout showAlert:show success:^(id responseObject) {
        
        if (success) {
            success(responseObject);
        }
        
        dispatch_group_leave(group);
    } failure:^(NSError *error) {
        NSMutableArray *arrayM = objc_getAssociatedObject(group, &groupErrorKey);
        [arrayM addObject:error];
        
        if (failure) {
            failure(error);
        }
        
        dispatch_group_leave(group);
    }];
}

- (void)sendGroupPostRequest:(BlockAction)requests success:(BlockAction)success failure:(GroupResponseFailure)failure {
    if (requests == nil) {
        return;
    }
    
    dispatch_group_t group = dispatch_group_create();
    objc_setAssociatedObject(group, &groupErrorKey, [NSMutableArray array], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    Method originalPost = class_getInstanceMethod(self.class, @selector(sendPOSTRequest:withData:withTimeout:showAlert:success:failure:));
    Method groupPost = class_getInstanceMethod(self.class, @selector(sendPOSTRequestInGroup:withData:withTimeout:showAlert:success:failure:));
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    objc_setAssociatedObject(queue, &queueGroupKey, group, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    queue.qualityOfService = NSQualityOfServiceUserInitiated;
    queue.maxConcurrentOperationCount = 3;
    
    [queue addOperationWithBlock:^{
        
        method_exchangeImplementations(originalPost, groupPost);
        requests();
        // 发出请求后就可以替换回original method，不必等待回调，尽量减小替换的时间窗口
        method_exchangeImplementations(originalPost, groupPost);
        
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            NSMutableArray *arrayM = objc_getAssociatedObject(group, &groupErrorKey);
            if (arrayM.count > 0) {
                if (failure) {
                    failure(arrayM.copy);
                }
            } else if (success) {
                success();
            }
            
        });
    }];
}

@end
