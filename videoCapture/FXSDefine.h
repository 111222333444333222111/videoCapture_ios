//
//  AppKit.h
//
//  Created by Mr.Sen on 13-12-9.
//  Copyright (c) 2013年 炎翔通信. All rights reserved.
//

//Log
#ifdef DEBUG
#define DeBugLog(...) NSLog(__VA_ARGS__)
#define DeBugMethod() NSLog(@"%s", __func__)
#else
#define DeBugLog(...)
#define DeBugMethod()
#endif

#define kMemoryOut(class) NSLog(@"%s内存溢出", object_getClassName(class));

//app版本号
#define kAppVersion [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]
//appbuild版本号
#define kAppBuildVersion [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]
//获取手机型号
#define kPhoneModel [UIDevice currentDevice].model

//获取设备物理的高度
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
//获取设备物理的宽度
#define kScreenWidth [UIScreen mainScreen].bounds.size.width

//设备版本号
#define kSystemVersion [[[UIDevice currentDevice].systemVersion substringToIndex:1] integerValue]
//判断IOS?或更高
#define NLSystemVersionGreaterOrEqualThan(version) ([[[UIDevice currentDevice] systemVersion] floatValue] >= version)
#define IOS6_OR_LATER NLSystemVersionGreaterOrEqualThan(6.0)
#define IOS7_OR_LATER NLSystemVersionGreaterOrEqualThan(7.0)
#define IOS8_OR_LATER NLSystemVersionGreaterOrEqualThan(8.0)

#define kDegreesToRadians(x) (M_PI*(x)/180.0)

#define kAnimTimeInterval 0.3f

//判断设备是否为iphone5
#define DEVICE_IS_IPHONE5 ([[UIScreen mainScreen] bounds].size.height == 568)

#define iPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)

//View
#define kViewControllerWithNib(aName) [[NSClassFromString(aName) alloc] initWithNibName:aName bundle:nil]
#define kViewWithLoadNib(aName, aOwner) [[[NSBundle mainBundle] loadNibNamed:aName owner:aOwner options:nil] lastObject]
#define kAlertView(aTitle, aMessage, aCancelTitle) [[[UIAlertView alloc] initWithTitle:aTitle message:aMessage delegate:nil cancelButtonTitle:aCancelTitle otherButtonTitles:nil] show];

//读取本地文件
#define kFilePath(aFile, aType) [[NSBundle mainBundle] pathForResource:aFile ofType:aType]
//读取文件的文本内容,默认编码为UTF-8
#define kStringWithFile(aFile, aType) [[NSString alloc] initWithContentsOfFile:kFilePath(aFile, aType) encoding:NSUTF8StringEncoding error:nil]
#define kDictionaryWithFile(aFile, aType) [[NSDictionary alloc] initWithContentsOfFile:kFilePath(aFile, aType)]
#define kArrayWithFile(aFile, aType) [[NSArray alloc] initWithContentsOfFile:kFilePath(aFile, aType)]

//----------------------图片相关--------------------------
//读取本地图片
#define kImageWithFile(aFile, aType) [UIImage imageWithContentsOfFile:kFilePath(aFile, aType)]
//定义UIImage对象
#define kImageWithName(aName) [UIImage imageNamed:aName]
//可拉伸的图片
#define kResizableImage(name, top, left, bottom, right) [[UIImage imageNamed:name] resizableImageWithCapInsets:UIEdgeInsetsMake(top, left, bottom, right)]
#define kResizableImageWithMode(name, top, left, bottom, right, mode) [[UIImage imageNamed:name] resizableImageWithCapInsets:UIEdgeInsetsMake(top, left, bottom, right) resizingMode:mode]
//建议使用前两种宏定义,性能高于后者
//----------------------图片相关--------------------------

//----------------------颜色相关--------------------------
//获取RGBA颜色
#define kColor(r, g, b, a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a/1.0f]
//RGB颜色转换（16进制->10进制）
#define kColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
//背景色
#define kBackgroundColor [UIColor colorWithRed:242.0/255.0 green:236.0/255.0 blue:231.0/255.0 alpha:1.0]
//清除背景色
#define kClearColor [UIColor clearColor]
//半透明
#define kTranslucentColor [UIColor colorWithRed:0 green:0 blue:0 alpha:0.44]
//标题色
#define kTitleColor [UIColor colorWithRed:2/255.0f green:143/255.0f blue:214/255.0f alpha:1/1.0f]
//----------------------颜色相关--------------------------

//----------------------字体相关--------------------------
//获取字体
#define kFont(size) [UIFont systemFontOfSize:size]
//标题字体
#define kTitleFont [UIFont systemFontOfSize:20]
//----------------------字体相关--------------------------

//G－C－D
#define kBACK(block) dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block)
#define kMAIN(block) dispatch_async(dispatch_get_main_queue(), block)

//Alert
#define kALERT(msg) [[[UIAlertView alloc] initWithTitle:nil message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show]

//由角度获取弧度 有弧度获取角度
#define kDegreesToRadian(x) (M_PI *(x) /180.0)
#define kRadianToDegrees(radian) (radian *180.0) /(M_PI)

//MBProgressHUD
#import <MBProgressHUD.h>
#define kMBProgressHUDToastDelay(aView, yoffset, aText, aDelay) {\
MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:aView animated:YES];\
hud.mode = MBProgressHUDModeText;\
hud.yOffset = yoffset;\
hud.removeFromSuperViewOnHide = YES;\
hud.labelText = aText;\
[hud hide:YES afterDelay:aDelay];\
}\

#define kMBProgressHUDToast(aView, yoffset, aText) kMBProgressHUDToastDelay(aView, yoffset, aText, 1.0f)
#define kMBProgressHUD(aView, aText) kMBProgressHUDToast(aView, 0.0f, aText)


