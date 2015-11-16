//
//  ServiceManager.h
//  videoCapture
//
//  Created by video on 15/11/5.
//  Copyright © 2015年 Hinson.Von. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <YYModel.h>

#import "FXSDefine.h"

#import "Model.h"
#import "Utils.h"

typedef void(^ServiceCallBack)(BOOL isSuccess, id result, NSError *error);

@interface ServiceManager : NSObject

+ (void)loginWithDevID:(NSString *)devid DevKey:(NSString *)devkey ConVer:(NSString *)versionName callBack:(ServiceCallBack)callBack;

+ (void)recordStartWithDevID:(NSString *)devid DevKey:(NSString *)devkey callBack:(ServiceCallBack)callBack;

+ (void)recordEndWithDevID:(NSString *)devid DevKey:(NSString *)devkey callBack:(ServiceCallBack)callBack;

@end
