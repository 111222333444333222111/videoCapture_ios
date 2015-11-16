//
//  ServiceManager.m
//  videoCapture
//
//  Created by video on 15/11/5.
//  Copyright © 2015年 Hinson.Von. All rights reserved.
//

#import "ServiceManager.h"

#import <AFNetworking.h>

@implementation ServiceManager

+ (NSString *)IP:(NSString *)action {
    NSMutableDictionary *dic = [Utils readVideoCaptureSetting];
    NSString *ip = [dic objectForKey:VideoCapture_IP];
    NSString *port = [dic objectForKey:VideoCapture_Port];
    //101.95.49.78:8081
//    ip = @"101.95.49.78";
    ip = @"192.168.31.180";
    port = @"8081";
    NSString *res = [NSString stringWithFormat:@"http://%@:%@/livestreamservice/mobile_%@.do", ip, port, action];
    NSLog(@"地址=%@", res);
    return res;
}

#pragma mark - 执行
+ (void)executeWithUrl:(NSString *)urlString parameters:(NSDictionary *)parameters callBack:(ServiceCallBack)callBack
{
/*
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", nil];
    [manager POST:urlString parameters:parameters success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        if (callBack) {
            NSLog(@"suc ： %@", operation.responseString);
            LoginRes *res = [LoginRes yy_modelWithJSON:responseObject];
            callBack(YES, res, nil);
        }
    } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
        if (callBack) {
            callBack(NO, nil, error);
        }
    }];
*/
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager POST:urlString parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        if (callBack) {
            NSLog(@"suc ： %@", responseObject);
            callBack(YES, responseObject, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (callBack) {
            callBack(NO, nil, error);
        }
    }];
}

+ (void)loginWithDevID:(NSString *)devid DevKey:(NSString *)devkey ConVer:(NSString *)versionName callBack:(ServiceCallBack)callBack {
    
    NSString *url = [self IP:@"devLogin"];
    NSDictionary *parameters = @{@"DevID" : devid,
                                 @"DevKey" : devkey,
                                 @"SourceType" : @"1",
                                 @"ConType" : @"1",
                                 @"ConVer" : versionName};
    [self executeWithUrl:url parameters:parameters callBack:callBack];
}

+ (void)recordStartWithDevID:(NSString *)devid DevKey:(NSString *)devkey callBack:(ServiceCallBack)callBack {
    
    NSString *url = [self IP:@"recordStart"];
    NSDictionary *parameters = @{@"DevID" : devid,
                                 @"DevKey" : devkey,
                                 @"Imsi" : @"",
                                 @"Protocol" : @"rtsp"};
    [self executeWithUrl:url parameters:parameters callBack:callBack];
}

+ (void)recordEndWithDevID:(NSString *)devid DevKey:(NSString *)devkey callBack:(ServiceCallBack)callBack {
    
    NSString *url = [self IP:@"recordEnd"];
    NSDictionary *parameters = @{@"DevID" : devid,
                                 @"DevKey" : devkey};
    [self executeWithUrl:url parameters:parameters callBack:callBack];
}

@end
