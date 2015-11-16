//
//  Utils.h
//  videoCapture
//
//  Created by video on 15/11/5.
//  Copyright © 2015年 Hinson.Von. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  IP
 */
static NSString *const VideoCapture_IP = @"IP";

/**
 *  端口
 */
static NSString *const VideoCapture_Port = @"Port";

/**
 *  分辨率数组
 */
static NSString *const VideoCapture_Resolutions = @"Resolutions";

/**
 *  默认分辨率
 */
static NSString *const VideoCapture_Resolution = @"Resolution";

/**
 *  帧率
 */
static NSString *const VideoCapture_Frame = @"Frame";

/**
 *  码率
 */
static NSString *const VideoCapture_Code = @"Code";


@interface Utils : NSObject

+ (NSMutableDictionary *)readVideoCaptureSetting;
+ (void)saveVideoCaptureSetting:(nonnull NSDictionary *)setting;

+ (NSString *)readUserName;
+ (void)saveUserName:(NSString *)name;

+ (NSString *)readUserPwd;
+ (void)saveUserPwd:(NSString *)pwd;

+ (BOOL)readAutoLogin;
+ (void)saveAutoLogin:(BOOL)isAutoLogin;

@end

NS_ASSUME_NONNULL_END
