//
//  MainViewController.m
//  videoCapture
//
//  Created by video on 15/11/5.
//  Copyright © 2015年 Hinson.Von. All rights reserved.
//

#import "MainViewController.h"
#import <AVFoundation/AVFoundation.h>

#import "ServiceManager.h"

#import <KSYPushVideoStream/KSYPushVideoStream.h>

#define RTMP_HOST @"rtmp://183.131.21.161/live?vhost=test.uplive.ksyun.com/"

@interface MainViewController () {
    NSString *name;
    NSString *pwd;
    BOOL StartFlag;
}

@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@property (weak, nonatomic) IBOutlet UIButton *flightBtn;
@property (weak, nonatomic) IBOutlet UIButton *cameraBtn;
@property (weak, nonatomic) IBOutlet UIButton *settingBtn;

- (IBAction)recordAction:(UIButton *)sender;
- (IBAction)flightAction:(UIButton *)sender;
- (IBAction)cameraAction:(UIButton *)sender;
- (IBAction)settingAction:(UIButton *)sender;

@property AVCaptureDevice *device;

@property KSYPushVideoStream *pushVideoStream;

@end

@implementation MainViewController

- (void)dealloc {
    name = nil;
    pwd = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    name = [Utils readUserName];
    pwd = [Utils readUserPwd];
    NSLog(@"读取 用户名=%@/密码=%@", name, pwd);
    
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([_device hasTorch] && _device.torchMode == AVCaptureTorchModeOn) {
        [_flightBtn setImage:[UIImage imageNamed:@"ic_flash_on_holo_light"] forState:UIControlStateNormal];
    } else {
        [_flightBtn setImage:[UIImage imageNamed:@"ic_flash_off_holo_light"] forState:UIControlStateNormal];
    }
    
    __weak typeof(self) weakSelf = self;
    _pushVideoStream = [KSYPushVideoStream initialize];
    _pushVideoStream.pushErrorBlock = ^(PushStreamError error){
        if (error == PushStream_RTMP_OpenError) {
            UIAlertView *alertV = [[UIAlertView alloc] initWithTitle:nil message:@"RTMP打开失败" delegate:weakSelf cancelButtonTitle:nil otherButtonTitles:@"知道了", nil];
            [alertV show];
        }else if (error == PushStream_Device_Denied || error == PushStream_Device_Restricted){
            UIAlertView *alertV = [[UIAlertView alloc] initWithTitle:nil message:@"摄像头访问受限，请在设置隐私中打开" delegate:weakSelf cancelButtonTitle:nil otherButtonTitles:@"知道了", nil];
            [alertV show];
            
        }
    };
    [_pushVideoStream initWithDisplayView:self.view andCaptureDevicePosition:AVCaptureDevicePositionBack];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:)name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActiveNotification:)name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)recordAction:(UIButton *)sender {
    
    __weak typeof(self) weakSelf = self;
    if (!StartFlag) {
        [ServiceManager recordStartWithDevID:name DevKey:pwd callBack:^(BOOL isSuccess, id result, NSError *error) {
            if (isSuccess) {
                [weakSelf startRecord:result];
            } else {
                kMBProgressHUD(weakSelf.view, @"开启视频发生错误");
            }
        }];
    } else {
        //TODO: 关闭推流
        if ([_pushVideoStream isCapturing]) {
            [_pushVideoStream stopRecord];
        }
        
        [ServiceManager recordEndWithDevID:name DevKey:pwd callBack:^(BOOL isSuccess, id result, NSError *error) {
            if (isSuccess) {
                [weakSelf stopRecord:result];
            } else {
                kMBProgressHUD(weakSelf.view, @"停止视频发生错误");
            }
        }];
    }
}

- (void)startRecord:(id)result {
    if (result) {
        RecordStartRes *res = [RecordStartRes yy_modelWithJSON:result];
        NSString *Result = res.Result;
        if (Result && [Result isEqualToString:@"0"]) {
            
            StartFlag = YES;
            [_recordBtn setImage:[UIImage imageNamed:@"ic_switch_video_active"] forState:UIControlStateNormal];
            
            NSString *PublishUrl = res.PublishUrl;
            NSLog(@"PublishUrl = %@", PublishUrl);
            //TODO: 推流
            if (![_pushVideoStream isCapturing] && PublishUrl.length > 0) {
                _pushVideoStream.host = RTMP_HOST;
                _pushVideoStream.streamName = @"cuizhibo";
                
//                [_pushVideoStream setUrl:@"rtmp://test.uplive.ksyun.com/live/test_iOS_123"];
                [_pushVideoStream setUrl:PublishUrl];
                [_pushVideoStream startRecord];
            }
        } else
            kMBProgressHUD(self.view, @"开启视频失败");
    }
}

- (void)stopRecord:(id)result {
    if (result) {
        RecordEndRes *res = [RecordEndRes yy_modelWithJSON:result];
        NSString *Result = res.Result;
        if (Result && [Result isEqualToString:@"0"]) {
            kMBProgressHUD(self.view, @"停止视频成功");
            StartFlag = NO;
            [_recordBtn setImage:[UIImage imageNamed:@"ic_switch_video"] forState:UIControlStateNormal];
        } else
            kMBProgressHUD(self.view, @"停止视频失败");
    }
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    
    [_pushVideoStream stopRecord];
}

- (void)applicationDidBecomeActiveNotification:(NSNotification *)notification {
    [_pushVideoStream startRecord];
    
}

- (IBAction)flightAction:(UIButton *)sender {
    
    if (![_device hasTorch]) {//判断是否有闪光灯
        kMBProgressHUD(self.view, @"该设备无闪光灯");
    } else {
        [_device lockForConfiguration:nil];//锁定闪光灯
        if (_device.torchMode == AVCaptureTorchModeOff) {
            [_device setTorchMode: AVCaptureTorchModeOn];//打开闪光灯
            [_flightBtn setImage:[UIImage imageNamed:@"ic_flash_on_holo_light"] forState:UIControlStateNormal];
        } else {
            [_device setTorchMode: AVCaptureTorchModeOff];//关闭闪光灯
            [_flightBtn setImage:[UIImage imageNamed:@"ic_flash_off_holo_light"] forState:UIControlStateNormal];
        }
        [_device unlockForConfiguration]; //解除锁定
    }
}

- (IBAction)cameraAction:(UIButton *)sender {
    //TODO: 前后摄像头切换
    [_pushVideoStream changCamerType];
}

- (IBAction)settingAction:(UIButton *)sender {
    [self performSegueWithIdentifier:@"setting" sender:self];
}

@end
