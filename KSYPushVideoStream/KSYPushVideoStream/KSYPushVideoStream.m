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
- (instancetype)initWithDisplayView:(UIView *)displayView andCaptureDevicePosition:(AVCaptureDevicePosition)iCameraType {
    rtmp_init(&rtmpContext);
    _strRTMPUrl = nil;
    _videoPicker = [[KSYVideoPicker alloc] init];
    _videoPicker.devicePosition = iCameraType;
    [_videoPicker startup];
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
    return self;
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

- (void)stopCapture
{
    [_videoPicker stopCapture];
//    if (_videoPicker.isCapturing == YES) {
//        [_videoPicker stopCapture];
//    }
}
- (void)startRecord {
    
    // **** check rtmp url
    if (_strRTMPUrl == nil) {
        NSLog(@"========= ERROR: Please set rtmp url first! =========");
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
    NSLog(@"buffer length is %lu",(unsigned long)buffer.length);
    double tsOffset = _lastVideoTimestamp, timestamp = 0, lastVideoTimestamp = 0;
    
    for (KSYMP4Frame *f in frames) {
        if (f.type == kFrameTypeVideo) {
            lastVideoTimestamp = f.timestamp;
        }
        
        timestamp = tsOffset + f.timestamp;
        NSData *chunk = [NSData dataWithBytes:(char *)[buffer bytes] + f.offset
                                       length:f.size];
//        NSData *chunk1 = [NSData dataWithBytes:(char *)[chunk bytes] + 4
//                                       length:1];
//        Byte *bytes = (Byte *)[chunk1 bytes];
////        Byte *nalByte = (bytes + 4);
//        int res = ((int)bytes & 31);
//        if (res == 5) {
//            NSLog(@"========= ++++++ +++++++++++");
//        }
//        
//        NSLog(@" res = %@",@(res));
        NSLog(@"========= timestampFromFrame: %f, timestamp: %u, type: %@ =========",
              f.timestamp,
              (unsigned int)(timestamp * 1000),
              (f.type == kFrameTypeAudio ? @"audio" : @"video"));
        // lastTimestamp_ = f.timestamp + tsOffset;
        if (f.type == kFrameTypeAudio) {
            [_flvWriter writeAudioPacket:chunk timestamp:(unsigned long)(timestamp * 1000)];
        } else if (f.type == kFrameTypeVideo) {
            [_flvWriter writeVideoPacket:chunk
                               timestamp:(unsigned long)(timestamp * 1000)
                                    keyFrame:f.keyFrame
                     compositeTimeOffset:f.timeOffset];
        }
    }
    _lastVideoTimestamp += lastVideoTimestamp;
    

    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"_flvWriter.packet.length is %@",@(_flvWriter.packet.length));
        if (_flvWriter.packet.length > 200000) {
            NSLog(@"chunk is too big!");
        }
        int writeCode =  rtmp_write(rtmpContext, [_flvWriter.packet bytes], (int)_flvWriter.packet.length);
        
        [_flvWriter reset];
        
        NSLog(@"writeCode = %ld",(long)writeCode);

    });
    signal(SIGPIPE, SIG_IGN);


}



- (void)mp4MetaHeaderHandler:(KSYMP4Reader *)reader {
    KSYFLVMetadata *metadata = [self getFLVMetadata:_videoEncoder audio:_audioEncoder];
    
    if (!_isFlvMetaDataSend) {
        _flvWriter.debug = NO;
        [_flvWriter writeHeader];
        [_flvWriter writeMetaTag:metadata];
    }
    
    [_flvWriter writeVideoDecoderConfRecord:reader.videoDecoderBytes];
    [_flvWriter writeAudioDecoderConfRecord:reader.audioDecoderBytes];
    
    // [outputFileHandle seekToEndOfFile];
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
    metadata.framerate = 15;
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
