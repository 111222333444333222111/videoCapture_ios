//
//  Utils.m
//  videoCapture
//
//  Created by video on 15/11/5.
//  Copyright © 2015年 Hinson.Von. All rights reserved.
//

#import "Utils.h"

@implementation Utils

+ (NSMutableDictionary *)readVideoCaptureSetting {
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    id setting = [ud objectForKey:@"videoCaptureSetting"];
    if (!setting) {
        //不存在读取本地plist至NSUserDefaults
        NSString *path = [[NSBundle mainBundle] pathForResource:@"videoCapture" ofType:@"plist"];
        setting = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
        NSLog(@"%@", setting);
        [ud setObject:setting forKey:@"videoCaptureSetting"];
        [ud synchronize];
    }
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:setting];
    return dic;
}

+ (void)saveVideoCaptureSetting:(nonnull NSDictionary *)setting {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:setting forKey:@"videoCaptureSetting"];
    [ud synchronize];
}

+ (NSString *)readUserName {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    return [ud stringForKey:@"UserName"];
}

+ (void)saveUserName:(NSString *)name {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:name forKey:@"UserName"];
    [ud synchronize];
}

+ (NSString *)readUserPwd {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    return [ud stringForKey:@"UserPwd"];
}

+ (void)saveUserPwd:(NSString *)pwd {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:pwd forKey:@"UserPwd"];
    [ud synchronize];
}

+ (BOOL)readAutoLogin {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"isAutoLogin"];
}

+ (void)saveAutoLogin:(BOOL)isAutoLogin {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:isAutoLogin forKey:@"isAutoLogin"];
    [ud synchronize];
}

@end
