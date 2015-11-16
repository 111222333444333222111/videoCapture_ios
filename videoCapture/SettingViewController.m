//
//  SettingViewController.m
//  videoCapture
//
//  Created by video on 15/11/5.
//  Copyright © 2015年 Hinson.Von. All rights reserved.
//

#import "SettingViewController.h"

#import "Utils.h"

#import "FXSPickerView.h"

@interface SettingViewController ()<FXSPickerViewDataSource, FXSPickerViewDelegate> {
    NSMutableDictionary *dic;
    NSArray *Resolutions;
    NSNumber *index;
    NSString *frame;
    NSString *code;
}

@property (weak, nonatomic) IBOutlet UIButton *toDisBtn;
@property (weak, nonatomic) IBOutlet UITextField *frameTextField;
@property (weak, nonatomic) IBOutlet UITextField *codeTextField;

@end

@implementation SettingViewController

- (void)dealloc {
    dic = nil;
    Resolutions = nil;
    index = nil;
    frame = nil;
    code = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    dic = [Utils readVideoCaptureSetting];
    Resolutions = [dic objectForKey:VideoCapture_Resolutions];
    index = [dic objectForKey:VideoCapture_Resolution];
    NSString *Resolution = [Resolutions objectAtIndex:index.integerValue];
    //分辨率
    [_toDisBtn setTitle:Resolution forState:UIControlStateNormal];
    //帧率
    frame = [dic objectForKey:VideoCapture_Frame];
    _frameTextField.text = frame;
    //码率
    code = [dic objectForKey:VideoCapture_Code];
    _codeTextField.text = code;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (IBAction)toBackAction:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        NSLog(@"退出设置");
    }];
}

- (IBAction)toEditAction:(UIButton *)sender {
    if ([sender.titleLabel.text isEqualToString:@"编辑"]) {
        _toDisBtn.enabled = YES;
        _frameTextField.enabled = YES;
        _codeTextField.enabled = YES;
        [sender setTitle:@"保存" forState:UIControlStateNormal];
    } else {
        _toDisBtn.enabled = NO;
        _frameTextField.enabled = NO;
        _codeTextField.enabled = NO;
        [sender setTitle:@"编辑" forState:UIControlStateNormal];
        [self saveSetting];
    }
}

#pragma mark - 保存设置
- (void)saveSetting {
    frame = _frameTextField.text;
    code = _codeTextField.text;
    NSLog(@"%@/%@/%@", index, frame, code);
    [dic setValue:index forKey:VideoCapture_Resolution];
    [dic setValue:frame forKey:VideoCapture_Frame];
    [dic setValue:code forKey:VideoCapture_Code];
    NSLog(@"%@", dic);
    [Utils saveVideoCaptureSetting:dic];
}

#pragma mark - 设置分辨率
- (IBAction)toDisAction:(UIButton *)sender {
    FXSPickerView *pv = [[FXSPickerView alloc] initWithFrame:(CGRect){0, 0, self.view.frame.size.width, 300} title:@"分辨率"];
    pv.dataSource = self;
    pv.delegate = self;
    [pv.pickView selectRow:index.integerValue inComponent:0 animated:NO];
    [pv show:self.view];
}

- (NSInteger)numberOfComponentsInPickerView:(FXSPickerView *)pickerView {
    return 1;
}
- (NSInteger)pickerView:(FXSPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return Resolutions.count;
}
- (CGFloat)pickerView:(FXSPickerView *)pickerView widthForComponent:(NSInteger)component {
    return self.view.frame.size.width;
}
- (CGFloat)pickerView:(FXSPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 44;
}
- (NSString *)pickerView:(FXSPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return Resolutions[row];
}
- (void)pickerView:(FXSPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    index = @(row);
    [_toDisBtn setTitle:Resolutions[index.integerValue] forState:UIControlStateNormal];
}
- (void)pickerViewCancel:(FXSPickerView *)pickerView {
    
}
- (void)pickerViewConfirm:(FXSPickerView *)pickerView {
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
