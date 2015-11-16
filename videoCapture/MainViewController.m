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
}

- (IBAction)settingAction:(UIButton *)sender {
    [self performSegueWithIdentifier:@"setting" sender:self];
}

@end
