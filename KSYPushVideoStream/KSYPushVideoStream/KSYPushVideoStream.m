//
//  KSYPushVideoStream.m
//  KSYPushVideoStream
//
//  Created by Blues on 15/7/9.
//  Copyright (c) 2015年 Blues. All rights reserved.
//

#import "KSYPushVideoStream.h"
#import "KSYVideoPicker.h"
#import "KSYFLVWriter.h"
#import "KSYMP4Reader.h"
#import "KSYFLVMetadata.h"
#import "KSYFLVTag.h"
#import "ksyrtmp.h"
#import <sys/utsname.h>

NSString *const kIFFLVOutputWithRandom = @"ifflvout-%05d.flv";

@interface KSYPushVideoStream () {
    KSYVideoPicker *_videoPicker;
    LibRTMPContext *rtmpContext;
    
    NSMutableData *_streamBuffer;
    KSYFLVWriter  *_flvWriter;
    CGFloat _lastVideoTimestamp;
    
    NSString *_strRTMPUrl;
    
    KSYAudioEncoder *_audioEncoder;
    KSYVideoEncoder *_videoEncoder;
    CGFloat _audioBitRate;
    CGFloat _audioSampleRate;
    CGFloat _videoBitRate;
    CGFloat _videoMaxKeyFrame;
    CMVideoDimensions _videoDimensions;
    
    BOOL _isFlvMetaDataSend;
    
    NSFileHandle *_outputFileHandle;
    double _speed;
    UIView *_myView;
    NSArray *_arraySubViews;
    
    NSTimeInterval _videotimeCha;
    NSTimeInterval _audiotimeCha;
    int  _videoLengthps;
    int  _audioLengthps;
    BOOL    _test_Writing;
}

@end

@implementation KSYPushVideoStream

+ (KSYPushVideoStream *)initialize {
    static KSYPushVideoStream *shareObj = nil;
    static dispatch_once_t onceInit;
    dispatch_once(&onceInit, ^{
        shareObj = [[KSYPushVideoStream alloc] init];
    });
    return shareObj;
}

- (instancetype)initWithTestView:(UIView *)view
{
    rtmp_init(&rtmpContext);
    _strRTMPUrl = nil;
    _videoPicker = [[KSYVideoPicker alloc] init];
    _videoPicker.devicePosition = AVCaptureDevicePositionFront;
    [_videoPicker startup];
    [_videoPicker startPreview:view];
    // **** init default value
    _audioBitRate = 256000;
    _audioSampleRate = 44100;
    _videoBitRate = 500000;//1500000; // **** 可以调小更加流畅，清晰度降低，调大增加卡顿，清晰度提高
    _videoMaxKeyFrame = 200;
    _videoDimensions.width = 1024;
    _videoDimensions.height = 576;
    return self;

}
- (void)initWithDisplayView:(UIView *)displayView andCaptureDevicePosition:(AVCaptureDevicePosition)iCameraType {
    rtmp_init(&rtmpContext);
    _strRTMPUrl = nil;
    _videoPicker = [[KSYVideoPicker alloc] init];
    __weak PushErrorBlock block = _pushErrorBlock;

    _videoPicker.checkDeviceBlock = ^(DeviceAuthorized deviceLimits){
        if (block) {
            if (deviceLimits == Denied) {
                block (PushStream_Device_Denied);
            }
            else if (deviceLimits == Restricted)
            {
                block (PushStream_Device_Restricted);
            }
        }
    };
    [_videoPicker startup];

    _videoPicker.devicePosition = iCameraType;
    [_videoPicker startPreview:displayView];
    _myView = displayView ;
    // **** init default value
    _audioBitRate = 256000;
    _audioSampleRate = 44100;
    _videoBitRate = 500000;//1500000; // **** 可以调小更加流畅，清晰度降低，调大增加卡顿，清晰度提高
    _videoMaxKeyFrame = 200;
    _videoDimensions.width = 1024;
    _videoDimensions.height = 576;
    
    _arraySubViews = [displayView subviews];
    _videotimeCha = 0;
    _videoLengthps = 0;
    _audiotimeCha = 0;
    _audioLengthps = 0;
}

- (void)setCameraType:(AVCaptureDevicePosition)iCameraType { // **** front or back
    _videoPicker.devicePosition = iCameraType;
    
    [_videoPicker reStartUp];
    [_videoPicker replceView];
}

- (void)setUrl:(NSString *)strUrl {
    _strRTMPUrl = strUrl;
}

- (void)setVoiceType:(NSInteger)iVoiceType {
    // **** 设置 声音的类型？？？
}

- (void)setAudioEncodeConfig:(NSInteger)audioSampleRate audioBitRate:(NSInteger)audioBitRate {
    // **** 设置音频的 采样率 和 比特率
    _audioBitRate = audioBitRate;
    _audioSampleRate = audioSampleRate;
}

- (void)setVideoEncodeConfig:(NSInteger)videoFrameRate videoBitRate:(NSInteger)videoBitRate {
    // **** 设置视频的 采样率 和 最大帧率
    _videoMaxKeyFrame = videoFrameRate;
    _videoBitRate = videoBitRate;
}

- (void)setVideoResolutionWithWidth:(CGFloat)videoWidth andHeight:(CGFloat)videoHeight {
    // **** 设置视频的resolution
    _videoDimensions.width = videoWidth;
    _videoDimensions.height = videoHeight;
}

//- (void)setDropFrameFrequency:(NSInteger)frequency {
//    // **** 设置丢帧的频率
//}


- (void)startCapture
{
    
//    [_videoPicker startCaptureTest];
    // **** start capture video and send to rtmp server

    __weak id weakSelf = self;
    [_videoPicker startCaptureWithEncoder:_videoEncoder
                                    audio:_audioEncoder
                             captureBlock:^(NSArray *frames, NSData *buffer) {
                                 NSLog(@"========= Buffer: %ld bytes, %ld frames =========", (long)buffer.length, (long)frames.count);
                                 if (buffer != nil && frames.count > 0) {
                                     [weakSelf captureHandleByCompletedMP4Frames:frames buffer:buffer];
                                 }
                             } metaHeaderBlock:^(KSYMP4Reader *reader) {
                                 [weakSelf mp4MetaHeaderHandler:reader];
                             } failureBlock:^(NSError *error) {
                                 NSLog(@"========= Error: %@ =========", error);
                             }];

}

- (void)stopCapture
{
    [_videoPicker stopCapture];
//    if (_videoPicker.isCapturing == YES) {
//        [_videoPicker stopCapture];
//    }
}

- (NSString *)systemDeviceTypeFormatted:(BOOL)formatted {
    // Set up a Device Type String
    NSString *DeviceType;
    
    // Check if it should be formatted
    if (formatted) {
        // Formatted
        @try {
            // Set up a new Device Type String
            NSString *NewDeviceType;
            // Set up a struct
            struct utsname DT;
            // Get the system information
            uname(&DT);
            // Set the device type to the machine type
            DeviceType = [NSString stringWithFormat:@"%s", DT.machine];
            
            if ([DeviceType isEqualToString:@"i386"])
                NewDeviceType = @"iPhoneSimulator";
            else if ([DeviceType isEqualToString:@"x86_64"])
                NewDeviceType = @"iPhoneSimulator";
            else if ([DeviceType isEqualToString:@"iPhone1,1"])
                NewDeviceType = @"iPhone";
            else if ([DeviceType isEqualToString:@"iPhone1,2"])
                NewDeviceType = @"iPhone3G";
            else if ([DeviceType isEqualToString:@"iPhone2,1"])
                NewDeviceType = @"iPhone3GS";
            else if ([DeviceType isEqualToString:@"iPhone3,1"])
                NewDeviceType = @"iPhone4";
            else if ([DeviceType isEqualToString:@"iPhone4,1"])
                NewDeviceType = @"iPhone4S";
            else if ([DeviceType isEqualToString:@"iPhone5,1"])
                NewDeviceType = @"iPhone5_GSM";
            else if ([DeviceType isEqualToString:@"iPhone5,2"])
                NewDeviceType = @"iPhone5_GSM-CDMA";
            else if ([DeviceType isEqualToString:@"iPhone5,3"])
                NewDeviceType = @"iPhone5c_GSM";
            else if ([DeviceType isEqualToString:@"iPhone5,4"])
                NewDeviceType = @"iPhone5c_GSM-CDMA)";
            else if ([DeviceType isEqualToString:@"iPhone6,1"])
                NewDeviceType = @"iPhone5s_GSM";
            else if ([DeviceType isEqualToString:@"iPhone6,2"])
                NewDeviceType = @"iPhone5s_GSM-CDMA";
            else if ([DeviceType isEqualToString:@"iPhone7,1"])
                NewDeviceType = @"iPhone6Plus";
            else if ([DeviceType isEqualToString:@"iPhone7,2"])
                NewDeviceType = @"iPhone6";
            else if ([DeviceType isEqualToString:@"iPhone8,1"])
                NewDeviceType = @"iPhone6SPlus";
            else if ([DeviceType isEqualToString:@"iPhone8,2"])
                NewDeviceType = @"iPhone6S";
            else if ([DeviceType isEqualToString:@"iPod1,1"])
                NewDeviceType = @"iPodTouch1G";
            else if ([DeviceType isEqualToString:@"iPod2,1"])
                NewDeviceType = @"iPodTouch2G";
            else if ([DeviceType isEqualToString:@"iPod3,1"])
                NewDeviceType = @"iPodTouch3G";
            else if ([DeviceType isEqualToString:@"iPod4,1"])
                NewDeviceType = @"iPodTouch4G";
            else if ([DeviceType isEqualToString:@"iPod5,1"])
                NewDeviceType = @"iPodTouch5G";
            else if ([DeviceType isEqualToString:@"iPad1,1"])
                NewDeviceType = @"iPad";
            else if ([DeviceType isEqualToString:@"iPad2,1"])
                NewDeviceType = @"iPad2_WiFi";
            else if ([DeviceType isEqualToString:@"iPad2,2"])
                NewDeviceType = @"iPad2_GSM";
            else if ([DeviceType isEqualToString:@"iPad2,3"])
                NewDeviceType = @"iPad2_CDMA";
            else if ([DeviceType isEqualToString:@"iPad2,4"])
                NewDeviceType = @"iPad2_WiFi-New-Chip)";
            else if ([DeviceType isEqualToString:@"iPad2,5"])
                NewDeviceType = @"iPadmini_WiFi";
            else if ([DeviceType isEqualToString:@"iPad2,6"])
                NewDeviceType = @"iPadmini_GSM";
            else if ([DeviceType isEqualToString:@"iPad2,7"])
                NewDeviceType = @"iPadmini_GSM-CDMA";
            else if ([DeviceType isEqualToString:@"iPad3,1"])
                NewDeviceType = @"iPad3_WiFi";
            else if ([DeviceType isEqualToString:@"iPad3,2"])
                NewDeviceType = @"iPad3_GSM-CDMA";
            else if ([DeviceType isEqualToString:@"iPad3,3"])
                NewDeviceType = @"iPad3_GSM";
            else if ([DeviceType isEqualToString:@"iPad3,4"])
                NewDeviceType = @"iPad4_WiFi";
            else if ([DeviceType isEqualToString:@"iPad3,5"])
                NewDeviceType = @"iPad4_GSM";
            else if ([DeviceType isEqualToString:@"iPad3,6"])
                NewDeviceType = @"iPad4_GSM-CDMA";
            else if ([DeviceType isEqualToString:@"iPad3,3"])
                NewDeviceType = @"NewiPad";
            else if ([DeviceType isEqualToString:@"iPad4,1"])
                NewDeviceType = @"iPadAir_WiFi";
            else if ([DeviceType isEqualToString:@"iPad4,2"])
                NewDeviceType = @"iPadAir_Cellular";
            else if ([DeviceType isEqualToString:@"iPad4,4"])
                NewDeviceType = @"iPadmini2_WiFi";
            else if ([DeviceType isEqualToString:@"iPad4,5"])
                NewDeviceType = @"iPadmini2_Cellular";
            else if ([DeviceType hasPrefix:@"iPad"])
                NewDeviceType = @"iPad";
            
            // Return the new device type
            return NewDeviceType;
        }
        @catch (NSException *exception) {
            // Error
            return @"";
        }
    } else {
        // Unformatted
        @try {
            // Set up a struct
            struct utsname DT;
            // Get the system information
            uname(&DT);
            // Set the device type to the machine type
            DeviceType = [NSString stringWithFormat:@"%s", DT.machine];
            
            // Return the device type
            return DeviceType;
        }
        @catch (NSException *exception) {
            // Error
            return nil;
        }
    }
}


//随机数
- (NSString *)getTimeAndRandom{
    int iRandom=arc4random();
    if (iRandom<0) {
        iRandom=-iRandom;
    }
    NSString *tResult=[NSString stringWithFormat:@"%d",iRandom];
    if (tResult.length > 6) {
        return [tResult substringToIndex:6];
    }
    return tResult;
}

// 设备名称
- (NSString *)deviceName {
    if ([[UIDevice currentDevice] respondsToSelector:@selector(name)]) {
        NSString *deviceName = [[UIDevice currentDevice] name];
        return deviceName;
    } else {
        return @"";
    }
}

- (void)startRecord {
    
    // **** check rtmp url
    
//    if (self.host == nil) {
//        NSLog(@"请检查主机名");
//        return;
//    }else if (self.streamName == nil){
//        NSLog(@"请检查流名");
//        return;
//    }else {
//    
//        NSDate *  senddate=[NSDate date];
//        
//        NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
//        
//        [dateformatter setDateFormat:@"YYYY-MM-dd-hh-mm-ss"];
//        
//        NSString *  locationString=[dateformatter stringFromDate:senddate];
//        
//        NSLog(@"locationString:%@",locationString);
//        
//        _strRTMPUrl = [NSString stringWithFormat:@"%@%@_%@?vdoid=%@_%@",self.host,[self systemDeviceTypeFormatted:YES],[self getTimeAndRandom],[self systemDeviceTypeFormatted:YES],locationString];
//        NSLog(@"rtmpurl is %@",_strRTMPUrl);
//    }
    
    if (_strRTMPUrl == nil) {
        return;
    }
    if (_videoPicker.isCapturing == NO) {
        _streamBuffer = [[NSMutableData alloc] init];
        if(_flvWriter == nil)
        {
            _flvWriter = [[KSYFLVWriter alloc] init];

        }
    
        // **** test for save video file to check
        NSFileManager *fileManager = [NSFileManager defaultManager];
//        NSString *strFLVVideoName = [NSString stringWithFormat:kIFFLVOutputWithRandom, rand() % 9];

        NSString *strFLVVideoName = [NSString stringWithFormat:@"ifflvout.flv"];
        NSString *strFLVVideoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:strFLVVideoName];
        [fileManager removeItemAtPath:strFLVVideoPath error:nil];
        [fileManager createFileAtPath:strFLVVideoPath contents:nil attributes:nil];
        NSLog(@"File Path: %@", strFLVVideoPath);
        
        _outputFileHandle = [NSFileHandle fileHandleForWritingAtPath:strFLVVideoPath];
        rtmp_seturl(rtmpContext, (char *)[_strRTMPUrl UTF8String]);
        NSInteger openResultCode = rtmp_open(rtmpContext, WRITE_FLAGS);
        NSLog(@"Open Code: %ld", (long)openResultCode);
        if (openResultCode != 0) {
            if (self.pushErrorBlock) {
                self.pushErrorBlock(PushStream_RTMP_OpenError);
            }
            return;

        }
        // **** audio - 64 kbos, sample rate is 441000
        _audioEncoder = [KSYAudioEncoder createAACAudioWithBitRate:_audioBitRate sampleRate:_audioSampleRate];
        _videoEncoder = [KSYVideoEncoder createH264VideoWithDimensions:_videoDimensions bitRate:_videoBitRate maxKeyFrame:_videoMaxKeyFrame];

        // **** start capture video and send to rtmp server
        [_videoPicker startCaptureWithEncoder:_videoEncoder
                                        audio:_audioEncoder
                                 captureBlock:^(NSArray *frames, NSData *buffer) {
                                     NSLog(@"========= Buffer: %ld bytes, %ld frames =========", (long)buffer.length, (long)frames.count);
                                     if (buffer != nil && frames.count > 0) {
                                         [self captureHandleByCompletedMP4Frames:frames buffer:buffer];
                                     }
                                 } metaHeaderBlock:^(KSYMP4Reader *reader) {
                                     [self mp4MetaHeaderHandler:reader];
                                 } failureBlock:^(NSError *error) {
                                     NSLog(@"========= Error: %@ =========", error);
                                 }];
    }
}

- (void)stopRecord {
    if (_videoPicker.isCapturing == YES) {
        [_videoPicker stopCapture];
        rtmp_close(rtmpContext);
        
        [_outputFileHandle closeFile];
    }
}

- (BOOL)isCapturing {
    return _videoPicker.isCapturing;
}

#pragma mark - Helper 

- (void)captureHandleByCompletedMP4Frames:(NSArray *)frames buffer:(NSData *)buffer {
    _test_Writing = NO;
    
    double tsOffset = _lastVideoTimestamp, timestamp = 0, lastVideoTimestamp = 0;

    for (KSYMP4Frame *f in frames) {
        _test_Writing = YES;
        if (f.type == kFrameTypeVideo) {
            lastVideoTimestamp = f.timestamp;
        }
        
        timestamp = tsOffset + f.timestamp;
        NSData *chunk = [NSData dataWithBytes:(char *)[buffer bytes] + f.offset
                                       length:f.size];

//        NSLog(@"chunk is %@",@(chunk.length));
//        NSLog(@"========= timestampFromFrame: %f, timestamp: %u, type: %@ =========",
//              f.timestamp,
//              (unsigned int)(timestamp * 1000),
//              (f.type == kFrameTypeAudio ? @"audio" : @"video"));
        
        // lastTimestamp_ = f.timestamp + tsOffset;
        if (f.type == kFrameTypeAudio) {
            [_flvWriter writeAudioPacket:chunk timestamp:(unsigned long)(timestamp * 1000)];
        } else if (f.type == kFrameTypeVideo) {
            [_flvWriter writeVideoPacket:chunk
                               timestamp:(unsigned long)(timestamp * 1000)
                                    keyFrame:f.keyFrame
                     compositeTimeOffset:f.timeOffset];
        }
        
//            NSLog(@"_flvWriter.packet.length is %@",@(_flvWriter.packet.length));
        
        
        
        NSTimeInterval bggain = [[NSDate date]timeIntervalSince1970];
        

        int writeCode =  rtmp_write(rtmpContext, [_flvWriter.packet bytes], (int)_flvWriter.packet.length);
        [_flvWriter reset];
        
        NSLog(@"writeCode = %ld",(long)writeCode);
        
        _lastVideoTimestamp += lastVideoTimestamp;

        NSTimeInterval end = [[NSDate date]timeIntervalSince1970];

        if (f.type == kFrameTypeAudio) {
            NSTimeInterval tempTimeC = end - bggain;
            _audiotimeCha += tempTimeC;
            _audioLengthps += writeCode;

        }else {
            NSTimeInterval tempTimeC = end - bggain;
            _videotimeCha += tempTimeC;
            _videoLengthps += writeCode;

        }


        
        NSLog(@"_timeCha = %lf",_videotimeCha);
        if (_videotimeCha > 1) {
            NSLog(@"视频码率 %0.0fkbp/s",_videoLengthps / _videotimeCha/1000);
            _videotimeCha = 0;
            _videoLengthps = 0;
        }
        
        if (_audiotimeCha > 1) {
            NSLog(@"音频码率 %0.0fkbp/s",_audioLengthps / _audiotimeCha/1000);
            _audiotimeCha = 0;
            _audioLengthps = 0;

        }

    }


}



- (void)mp4MetaHeaderHandler:(KSYMP4Reader *)reader {
    NSLog(@"metaHeader!");
    KSYFLVMetadata *metadata = [self getFLVMetadata:_videoEncoder audio:_audioEncoder];
    
    if (!_isFlvMetaDataSend) {
        _flvWriter.debug = NO;
        [_flvWriter writeHeader];
        [_flvWriter writeMetaTag:metadata];
    }
    
    [_flvWriter writeVideoDecoderConfRecord:reader.videoDecoderBytes];
    [_flvWriter writeAudioDecoderConfRecord:reader.audioDecoderBytes];
    
    // [outputFileHandle seekToEndOfFile];
    NSLog(@"metaHeader flvWriter.packet bytes length is %@",@(_flvWriter.packet.length));
    rtmp_write(rtmpContext, [_flvWriter.packet bytes], (int)_flvWriter.packet.length);
    //
    [_outputFileHandle writeData:_flvWriter.packet];
    
    if (!_isFlvMetaDataSend) {
        _isFlvMetaDataSend = YES;
    }
    
    [_flvWriter reset];
}

- (KSYFLVMetadata *)getFLVMetadata:(KSYVideoEncoder *)video audio:(KSYAudioEncoder *)audio {
    
    KSYFLVMetadata *metadata = [[KSYFLVMetadata alloc] init];
    // set video encoding metadata
    metadata.width = video.dimensions.width;
    metadata.height = video.dimensions.height;
    metadata.videoBitrate = video.bitRate / 1024.0;
    metadata.framerate = 25;
    metadata.videoCodecId = kFLVCodecIdH264;
    
    // set audio encoding metadata
    metadata.audioBitrate = audio.bitRate / 1024.0;
    metadata.sampleRate = audio.sampleRate;
    metadata.sampleSize = 16;// * 1024; // 16K
    metadata.stereo = YES;
    metadata.audioCodecId = kFLVCodecIdAAC;
    
    return metadata;
}

- (void)changCamerType
{
    [_videoPicker swapFrontAndBackCameras];
}


@end
