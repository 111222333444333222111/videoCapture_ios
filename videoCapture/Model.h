//
//  Model.h
//  videoCapture
//
//  Created by video on 15/11/5.
//  Copyright © 2015年 Hinson.Von. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LoginRes : NSObject
@property NSString *Result;//请求结果
@property NSString *UpgradeStatus;//升级状态 0-不升级/1-提示升级/2-强制升级
@property NSString *DownUrl;//下载地址
@property NSString *NewVer;
@end

@interface RecordStartRes : NSObject
@property NSString *Result;//请求结果
@property NSString *PublishUrl;//视频发布地址
@property NSString *AudioRtpPort;//视频Rtp端口
@property NSString *AudioRtcpPort;//视频Rtcp端口
@property NSString *VideoRtpPort;//音频Rtp端口
@property NSString *VideoRtcpPort;//音频Rtcp端口
@end

@interface RecordEndRes : NSObject
@property NSString *Result;//请求结果
@end

@interface Model : NSObject

@end
