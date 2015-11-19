//
//  KSYPushVideoStream.h
//  KSYPushVideoStream
//
//  Created by Blues on 15/7/9.
//  Copyright (c) 2015年 Blues. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef void(^PushVideoStreamBlock)(double speed);
@interface KSYPushVideoStream : NSObject

//单例
+ (KSYPushVideoStream *)initialize;

/**
 *  初始化推流工具
 *
 *  @param displayView 推流图像所展示的视图
 *  @param iCameraType 摄像头前置/后置
 *
 *  @return 推流工具
 */
- (instancetype)initWithDisplayView:(UIView *)displayView andCaptureDevicePosition:(AVCaptureDevicePosition)iCameraType;
/**
 *  开始录制
 */
- (void)startRecord;
/**
 *  停止录制
 */
- (void)stopRecord;
/**
 *  设置推流地址
 *
 *  @param strUrl 推流url
 */
- (void)setUrl:(NSString *)strUrl;
/**
 *  设置摄像头前后置
 *
 *  @param iCameraType 摄像头前置/后置样式
 */
- (void)setCameraType:(AVCaptureDevicePosition)iCameraType;
/**
 *  设置音频的 采样率 和 比特率
 *
 *  @param audioSampleRate 采样率
 *  @param audioBitRate    比特率
 */
- (void)setAudioEncodeConfig:(NSInteger)audioSampleRate audioBitRate:(NSInteger)audioBitRate;
/**
 *  设置视频的 采样率 和 最大帧率
 *
 *  @param videoFrameRate 最大帧率
 *  @param videoBitRate   比特率
 */
- (void)setVideoEncodeConfig:(NSInteger)videoFrameRate videoBitRate:(NSInteger)videoBitRate;
/**
 *  设置视频的分辨率
 *
 *  @param videoWidth 宽
 *  @param Height     高
 */
- (void)setVideoResolutionWithWidth:(CGFloat)videoWidth andHeight:(CGFloat)Height;
/**
 *  是否正在录像
 *
 *  @return 是否
 */
- (BOOL)isCapturing;

- (instancetype)initWithTestView:(UIView *)view;
- (void)changCamerType;
//- (void)setDropFrameFrequency:(NSInteger)frequency;
//- (void)setVoiceType:(NSInteger)iVoiceType;
//- (void)startCapture;
//- (void)stopCapture;
@end
