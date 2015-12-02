//
//  KSYVideoPicker.m
//  IFVideoPickerControllerDemo
//
//  Created by Blues on 3/25/13.
//  Copyright (c) 2015 KSY. All rights reserved.
//

#import "KSYVideoPicker.h"
#import "KSYVideoEncoder.h"
#import "KSYAudioEncoder.h"

@interface KSYVideoPicker () <AVCaptureVideoDataOutputSampleBufferDelegate,
AVCaptureAudioDataOutputSampleBufferDelegate> {
    id deviceConnectedObserver;
    id deviceDisconnectedObserver;
    captureHandler sampleBufferHandler_;
    AVCaptureVideoPreviewLayer *layer_;
    UIView                      *backgroundView_;
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position;
- (AVCaptureDevice *)frontFacingCamera;
- (AVCaptureDevice *)backFacingCamera;
- (AVCaptureDevice *)audioDevice;
- (void)startCapture:(KSYAVAssetEncoder *)encoder;

@property (nonatomic, strong)KSYAVAssetEncoder *assetEncoder_;
@end

// Safe release
#define SAFE_RELEASE(x) if (x) { [x release]; x = nil; }

#pragma mark -

@implementation KSYVideoPicker

const char *kVideoBufferQueueLabel = "com.ifactorylab.KSYVideoPicker.videoqueue";
const char *kAudioBufferQueueLabel = "com.ifactorylab.KSYVideoPicker.audioqueue";

@synthesize videoInput;
@synthesize audioInput;
@synthesize videoBufferOutput;
@synthesize audioBufferOutput;
@synthesize captureVideoPreviewLayer;
@synthesize videoPreviewView;
@synthesize isCapturing;
@synthesize session;

- (id)init {
    self = [super init];
    if (self !=  nil) {
        self.isCapturing = NO;
        
        __block id weakSelf = self;
        void (^deviceConnectedBlock)(NSNotification *) = ^(NSNotification *notification) {
            AVCaptureDevice *device = [notification object];
            
            BOOL sessionHasDeviceWithMatchingMediaType = NO;
            NSString *deviceMediaType = nil;
            if ([device hasMediaType:AVMediaTypeAudio]) {
                deviceMediaType = AVMediaTypeAudio;
            } else if ([device hasMediaType:AVMediaTypeVideo]) {
                deviceMediaType = AVMediaTypeVideo;
            }
            
            if (deviceMediaType != nil && session != nil) {
                for (AVCaptureDeviceInput *input in [self.session inputs]) {
                    if ([[input device] hasMediaType:deviceMediaType]) {
                        sessionHasDeviceWithMatchingMediaType = YES;
                        break;
                    }
                }
                
                if (!sessionHasDeviceWithMatchingMediaType) {
                    NSError	*error;
                    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
                    if ([self.session canAddInput:input])
                        [self.session addInput:input];
                }
            }
        };
        
        void (^deviceDisconnectedBlock)(NSNotification *) = ^(NSNotification *notification) {
            AVCaptureDevice *device = [notification object];
            
            if ([device hasMediaType:AVMediaTypeAudio]) {
                if (self.session) {
                    [self.session removeInput:[weakSelf audioInput]];
                }
                [weakSelf setAudioInput:nil];
            }
            else if ([device hasMediaType:AVMediaTypeVideo]) {
                if (self.session) {
                    [self.session removeInput:[weakSelf videoInput]];
                }
                [weakSelf setVideoInput:nil];
            }
        };
        
        // Create capture device with video input
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        deviceConnectedObserver =
        [notificationCenter addObserverForName:AVCaptureDeviceWasConnectedNotification
                                        object:nil
                                         queue:nil
                                    usingBlock:deviceConnectedBlock];
        deviceDisconnectedObserver =
        [notificationCenter addObserverForName:AVCaptureDeviceWasDisconnectedNotification
                                        object:nil
                                         queue:nil
                                    usingBlock:deviceDisconnectedBlock];
        
        
    }
    return self;
}

- (void)dealloc {
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:deviceConnectedObserver];
    [notificationCenter removeObserver:deviceDisconnectedObserver];
    
    [self shutdown];
}

- (DeviceAuthorized)checkDevice
{
    
    float version = [[[UIDevice currentDevice] systemVersion] floatValue]; //获取版本号
    

    if (version > 7.0 || version == 7.0) {
        NSString *mediaType = AVMediaTypeVideo;
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
        
        if(authStatus ==AVAuthorizationStatusRestricted){
            
            return Restricted;
            
        }
        
        else if(authStatus == AVAuthorizationStatusDenied){
            
            
            return Denied;
        }else {
            return Authorized;

        }


    }
    
    return 10;
    

}
- (BOOL)startup {
    
    DeviceAuthorized checkDevice = [self checkDevice];
    if (checkDevice != Authorized) {
        if (self.checkDeviceBlock) {
            self.checkDeviceBlock(checkDevice);
        }
        return NO;
    }
    if (session != nil) {
        // If session already exists, return NO.
        NSLog(@"Video session already exists, you must call shutdown current session first");
        return NO;
    }
    // Set torch and flash mode to auto
    // We use back facing camera by default
    AVCaptureDevice *backFacingCaemra = [self backFacingCamera];
    if (_devicePosition == AVCaptureDevicePositionFront) {
        backFacingCaemra = [self frontFacingCamera];
    }
    
    
    // Init the device inputs
    NSError *error;
    AVCaptureDeviceInput *newVideoInput =
    [[AVCaptureDeviceInput alloc] initWithDevice:backFacingCaemra error:&error];
    if (newVideoInput == nil) {
        NSLog(@"error is %@",error);
    }
    AVCaptureDeviceInput *newAudioInput =
    [[AVCaptureDeviceInput alloc] initWithDevice:[self audioDevice] error:nil];
    
    // Set up the video YUV buffer output
    dispatch_queue_t videoCaptureQueue =
    dispatch_queue_create(kVideoBufferQueueLabel, DISPATCH_QUEUE_SERIAL);
    
    AVCaptureVideoDataOutput *newVideoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [newVideoOutput setSampleBufferDelegate:self queue:videoCaptureQueue];
    
    // or kCVPixelFormatType_420YpCbCr8BiPlanarFullRange ??
    NSDictionary *videoSettings =
    [NSDictionary dictionaryWithObjectsAndKeys:
    [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange], kCVPixelBufferPixelFormatTypeKey, nil];
    newVideoOutput.videoSettings = videoSettings;
    
    // Set up the audio buffer output
    dispatch_queue_t audioCaptureQueue =
    dispatch_queue_create(kAudioBufferQueueLabel, DISPATCH_QUEUE_SERIAL);
    
    AVCaptureAudioDataOutput *newAudioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [newAudioOutput setSampleBufferDelegate:self queue:audioCaptureQueue];
    
    // Create session (use default AVCaptureSessionPresetHigh)
    AVCaptureSession *newSession = [[AVCaptureSession alloc] init];
    if (_devicePosition == AVCaptureDevicePositionBack) {
        newSession.sessionPreset = AVCaptureSessionPreset1920x1080;

    }else{
        newSession.sessionPreset = AVCaptureSessionPreset640x480;

    }
    
    // Add inputs and output to the capture session
    if ([newSession canAddInput:newVideoInput]) {
        [newSession addInput:newVideoInput];
    }
    
    if ([newSession canAddInput:newAudioInput]) {
        [newSession addInput:newAudioInput];
    }
    
    [self setSession:newSession];
    [self setVideoInput:newVideoInput];
    [self setAudioInput:newAudioInput];
    [self setVideoBufferOutput:newVideoOutput];
    [self setAudioBufferOutput:newAudioOutput];

    return YES;
}
- (void)reStartUp
{
    [self setSession:nil];
    [self setVideoInput:nil];
    [self setAudioInput:nil];
    [self setVideoBufferOutput:nil];
    [self setAudioBufferOutput:nil];

    AVCaptureDevice *backFacingCaemra = [self backFacingCamera];
    if (_devicePosition == AVCaptureDevicePositionFront) {
        backFacingCaemra = [self frontFacingCamera];
    }

    
    // Init the device inputs
    AVCaptureDeviceInput *newVideoInput =
    [[AVCaptureDeviceInput alloc] initWithDevice:backFacingCaemra error:nil];
    AVCaptureDeviceInput *newAudioInput =
    [[AVCaptureDeviceInput alloc] initWithDevice:[self audioDevice] error:nil];
    
    // Set up the video YUV buffer output
    dispatch_queue_t videoCaptureQueue =
    dispatch_queue_create(kVideoBufferQueueLabel, DISPATCH_QUEUE_SERIAL);
    
    AVCaptureVideoDataOutput *newVideoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [newVideoOutput setSampleBufferDelegate:self queue:videoCaptureQueue];
    
    // or kCVPixelFormatType_420YpCbCr8BiPlanarFullRange ??
    NSDictionary *videoSettings =
    [NSDictionary dictionaryWithObjectsAndKeys:
     [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange], kCVPixelBufferPixelFormatTypeKey, nil];
    newVideoOutput.videoSettings = videoSettings;
    
    // Set up the audio buffer output
    dispatch_queue_t audioCaptureQueue =
    dispatch_queue_create(kAudioBufferQueueLabel, DISPATCH_QUEUE_SERIAL);
    
    AVCaptureAudioDataOutput *newAudioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [newAudioOutput setSampleBufferDelegate:self queue:audioCaptureQueue];
    
    // Create session (use default AVCaptureSessionPresetHigh)
    AVCaptureSession *newSession = [[AVCaptureSession alloc] init];
    if (_devicePosition == AVCaptureDevicePositionBack) {
        newSession.sessionPreset = AVCaptureSessionPreset1920x1080;
        
    }else{
        newSession.sessionPreset = AVCaptureSessionPreset1280x720;
        
    }
    
    // Add inputs and output to the capture session
    if ([newSession canAddInput:newVideoInput]) {
        [newSession addInput:newVideoInput];
    }
    
    if ([newSession canAddInput:newAudioInput]) {
        [newSession addInput:newAudioInput];
    }
    
    [self setSession:newSession];
    [self setVideoInput:newVideoInput];
    [self setAudioInput:newAudioInput];
    [self setVideoBufferOutput:newVideoOutput];
    [self setAudioBufferOutput:newAudioOutput];


    
}
- (void)shutdown {
    [self stopCapture];
    [self stopPreview];
}

- (void)startPreview:(UIView *)view {
    backgroundView_ = view;
    [self startPreview:view withFrame:[view bounds] orientation:AVCaptureVideoOrientationPortrait];
}

- (void)startPreview:(UIView *)view withFrame:(CGRect)frame orientation:(AVCaptureVideoOrientation)orientation {
    AVCaptureVideoPreviewLayer *newCaptureVideoPreviewLayer =
    [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    
    CALayer *viewLayer = [view layer];
    [viewLayer setMasksToBounds:YES];
    
    [newCaptureVideoPreviewLayer setFrame:frame];
    if ([newCaptureVideoPreviewLayer respondsToSelector:@selector(connection)]) {
        if ([newCaptureVideoPreviewLayer.connection isVideoOrientationSupported]) {
            [newCaptureVideoPreviewLayer.connection setVideoOrientation:orientation];
        }
    } else {
        // Deprecated in 6.0; here for backward compatibility
        if ([newCaptureVideoPreviewLayer isOrientationSupported]) {
            [newCaptureVideoPreviewLayer setOrientation:orientation];
        }
    }

    
    
    [newCaptureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [viewLayer insertSublayer:newCaptureVideoPreviewLayer below:[[viewLayer sublayers] objectAtIndex:0]];
    layer_ = newCaptureVideoPreviewLayer;
    [self setVideoPreviewView:view];
    [self setCaptureVideoPreviewLayer:newCaptureVideoPreviewLayer];
    
    // Start the session. This is done asychronously since -startRunning doesn't
    //mreturn until the session is running.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [session startRunning];
    });
}

- (void)replceView
{
    AVCaptureVideoPreviewLayer *newCaptureVideoPreviewLayer =
    [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    
    CALayer *viewLayer = [backgroundView_ layer];
    [viewLayer setMasksToBounds:YES];
    
    [newCaptureVideoPreviewLayer setFrame:[backgroundView_ bounds]];
    if ([newCaptureVideoPreviewLayer respondsToSelector:@selector(connection)]) {
        if ([newCaptureVideoPreviewLayer.connection isVideoOrientationSupported]) {
            [newCaptureVideoPreviewLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        }
    } else {
        // Deprecated in 6.0; here for backward compatibility
        if ([newCaptureVideoPreviewLayer isOrientationSupported]) {
            [newCaptureVideoPreviewLayer setOrientation:AVCaptureVideoOrientationPortrait];
        }
    }
    
    [newCaptureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    //    [viewLayer insertSublayer:newCaptureVideoPreviewLayer below:[[viewLayer sublayers] objectAtIndex:0]];
    [viewLayer replaceSublayer:layer_ with:newCaptureVideoPreviewLayer];
    layer_ = newCaptureVideoPreviewLayer;
//    [self setVideoPreviewView:backgroundView_];
    [self setCaptureVideoPreviewLayer:newCaptureVideoPreviewLayer];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [session startRunning];
    });
}

- (void)replceWithView:(UIView *)view withFrame:(CGRect)frame orientation:(AVCaptureVideoOrientation)orientation {
    AVCaptureVideoPreviewLayer *newCaptureVideoPreviewLayer =
    [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    
    CALayer *viewLayer = [view layer];
    [viewLayer setMasksToBounds:YES];
    
    [newCaptureVideoPreviewLayer setFrame:frame];
    if ([newCaptureVideoPreviewLayer respondsToSelector:@selector(connection)]) {
        if ([newCaptureVideoPreviewLayer.connection isVideoOrientationSupported]) {
            [newCaptureVideoPreviewLayer.connection setVideoOrientation:orientation];
        }
    } else {
        // Deprecated in 6.0; here for backward compatibility
        if ([newCaptureVideoPreviewLayer isOrientationSupported]) {
            [newCaptureVideoPreviewLayer setOrientation:orientation];
        }
    }
    
    [newCaptureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
//    [viewLayer insertSublayer:newCaptureVideoPreviewLayer below:[[viewLayer sublayers] objectAtIndex:0]];
    [viewLayer replaceSublayer:layer_ with:newCaptureVideoPreviewLayer];
    layer_ = newCaptureVideoPreviewLayer;
    [self setVideoPreviewView:view];
    [self setCaptureVideoPreviewLayer:newCaptureVideoPreviewLayer];
    
    // Start the session. This is done asychronously since -startRunning doesn't
    //mreturn until the session is running.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [session startRunning];
    });
}

- (void)stopPreview {
    if (session == nil) {
        // Session has not created yet...
        return;
    }
    
    if (self.session.isRunning) {
        // There is no active session running...
        NSLog(@"You need to run startPreview first");
        [session stopRunning];

        return;
    }
    
    [session stopRunning];
}


- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

- (AVCaptureDevice *)frontFacingCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

- (AVCaptureDevice *) backFacingCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}


- (AVCaptureDevice *)audioDevice {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    if ([devices count] > 0) {
        return [devices objectAtIndex:0];
    }
    return nil;
}

- (void)startCapture:(KSYAVAssetEncoder *)encoder {
    [encoder start];
    
    // Add video and audio output to current capture session.
    if ([session canAddOutput:videoBufferOutput]) {
        [session addOutput:videoBufferOutput];
        
        for (AVCaptureConnection *c in videoBufferOutput.connections) {
            NSLog(@"Video stablization supported: %@", c.isVideoStabilizationSupported ? @"TRUE" : @"FALSE");
            NSLog(@"Video stablization enabled: %@", c.activeVideoStabilizationMode ? @"TRUE" : @"FALSE");
            if (c.isVideoStabilizationSupported) {
                c.preferredVideoStabilizationMode = YES;
            }
        }
    }
    
    if ([session canAddOutput:audioBufferOutput]) {
        [session addOutput:audioBufferOutput];
    }
    
    [self setIsCapturing:YES];
}

- (void)startCaptureWithEncoder:(KSYVideoEncoder *)video
                          audio:(KSYAudioEncoder *)audio
                   captureBlock:(encodedCaptureHandler)captureBlock
                metaHeaderBlock:(encodingMetaHeaderHandler)metaHeaderBlock
                   failureBlock:(encodingFailureHandler)failureBlock {

    if (self.assetEncoder_ == nil) {
        self.assetEncoder_ = [KSYAVAssetEncoder mpeg4BaseEncoder];
        self.assetEncoder_.videoEncoder = video;
        self.assetEncoder_.audioEncoder = audio;
        self.assetEncoder_.captureHandler = captureBlock;
        self.assetEncoder_.failureHandler = failureBlock;
        self.assetEncoder_.metaHeaderHandler = metaHeaderBlock;
    }
    
    [self startCapture:self.assetEncoder_];
}

- (void)startCaptureTest
{
    [self startCapture:self.assetEncoder_];

}
- (void)stopCapture {
    if (!isCapturing) {
        return;
    }
    
    // Clean up encoder objects which might have been set eariler.
    if (self.assetEncoder_ != nil) {
        [self.assetEncoder_ stop];
        self.assetEncoder_ = nil;
    }
    // Pull out video and audio output from current capture session.
    [session removeOutput:videoBufferOutput];
    [session removeOutput:audioBufferOutput];
    
    // Now, we are not capturing
    [self setIsCapturing:NO];
}


//- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
//{
//    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
//    for ( AVCaptureDevice *device in devices )
//        if ( device.position == position )
//            return device;
//    return nil;
//}

- (void)swapFrontAndBackCameras {
    // Assume the session is already running
    
    NSArray *inputs = self.session.inputs;
    for ( AVCaptureDeviceInput *input in inputs ) {
        AVCaptureDevice *device = input.device;
        if ( [device hasMediaType:AVMediaTypeVideo] ) {
            AVCaptureDevicePosition position = device.position;
            AVCaptureDevice *newCamera = nil;
            AVCaptureDeviceInput *newInput = nil;
            
            if (position == AVCaptureDevicePositionFront)
            {
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
                self.session.sessionPreset = AVCaptureSessionPreset1280x720;

            }

            else
            {
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
                self.session.sessionPreset = AVCaptureSessionPreset1280x720;

            }

            newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
            
            // beginConfiguration ensures that pending changes are not applied immediately

            [self.session beginConfiguration];
            
            [self.session removeInput:input];
            [self.session addInput:newInput];
            
            // Changes take effect once the outermost commitConfiguration is invoked.
            [self.session commitConfiguration];
            break;
        }
    } 
}
#pragma mark -
#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate

- (void) captureOutput:(AVCaptureOutput *)captureOutput
 didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
        fromConnection:(AVCaptureConnection *)connection {

    IFCapturedBufferType bufferType = kBufferUnknown;
    if (connection == [videoBufferOutput connectionWithMediaType:AVMediaTypeVideo]) {
        bufferType = kBufferVideo;
    } else if (connection == [audioBufferOutput connectionWithMediaType:AVMediaTypeAudio]) {
        bufferType = kBufferAudio;
    }
    
    if (self.assetEncoder_ != nil) {
        [self.assetEncoder_ encodeSampleBuffer:sampleBuffer ofType:bufferType];
    } else {
        if (sampleBufferHandler_ != nil) {
            sampleBufferHandler_(sampleBuffer, bufferType);
        } else {
            NSLog(@"No sample buffer capture handler exist");
        }
    }
}

@end
