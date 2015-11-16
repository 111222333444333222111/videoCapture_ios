//
//  LoginViewController.m
//  videoCapture
//
//  Created by video on 15/11/5.
//  Copyright © 2015年 Hinson.Von. All rights reserved.
//

#import "LoginViewController.h"

#import "ServiceManager.h"

@interface LoginViewController () {
    BOOL isAutoLogin;
    NSString *name;
    NSString *pwd;
}

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *pwdTextField;
@property (weak, nonatomic) IBOutlet UIButton *autoLoginBtn;

@end

@implementation LoginViewController

- (void)dealloc {
    name = nil;
    pwd = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    isAutoLogin = [Utils readAutoLogin];
    
    name = [Utils readUserName];
    pwd = [Utils readUserPwd];
    NSLog(@"读取 用户名=%@/密码=%@", name, pwd);
    
    _nameTextField.text = name;
    _pwdTextField.text = pwd;
    
    _autoLoginBtn.selected = isAutoLogin;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //自动登录
//    if (isAutoLogin && name.length > 0 && pwd.length > 0) {
//        [self performSelector:@selector(toLogin) withObject:nil afterDelay:3.];
//    }
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

- (IBAction)autoLoginAction:(UIButton *)sender {
    BOOL selected = sender.selected;
    isAutoLogin = !selected;
    [Utils saveAutoLogin:isAutoLogin];
    sender.selected = isAutoLogin;
}

- (IBAction)toLoginAction:(UIButton *)sender {
    name = _nameTextField.text;
    pwd = _pwdTextField.text;
    if (name.length == 0 || pwd.length == 0) {
        kMBProgressHUD(self.view, @"用户名或密码不能为空");
        return;
    }
    //保存
    [Utils saveUserName:name];
    [Utils saveUserPwd:pwd];
    
    //TODO: 登录
    [self toLogin];
}

- (void)toLogin {
    __weak typeof(self) weakSelf = self;
    [ServiceManager loginWithDevID:name DevKey:pwd ConVer:kAppVersion callBack:^(BOOL isSuccess, id result, NSError *error) {
        if (isSuccess) {
            [weakSelf showMain:result];
        } else {
            kMBProgressHUD(weakSelf.view, @"登录发生错误");
        }
    }];
}

- (void)showMain:(id)result {
    LoginRes *res = [LoginRes yy_modelWithJSON:result];
    NSString *Result = res.Result;
    if (Result && [Result isEqualToString:@"0"]) {
        [self performSegueWithIdentifier:@"login" sender:self];
    } else
        kMBProgressHUD(self.view, @"登录失败");
}

@end
