//
//  KDPickerView.m
//  PhoneGuard
//
//  Created by Mr.Sen on 14-4-18.
//  Copyright (c) 2014年 炎翔通信. All rights reserved.
//

#import "FXSPickerView.h"
#import "FXSDefine.h"

#define downHeight 240
#define downTopHeight 44

@implementation FXSPickerView
{
    UIView *downView;
}

- (void)dealloc
{
    _delegate = nil;
    _dataSource = nil;
    _pickView = nil;
    downView = nil;
}

- (id)initWithFrame:(CGRect)frame title:(NSString *)title
{
    if (kSystemVersion >= 7) {
        frame = (CGRect){0, 0, frame.size};
    }
    self = [super initWithFrame:frame];
    if (self) {

        self.backgroundColor = kColor(0, 0, 0, 0.5);
        
        //点击消失
        UIView *upView = [[UIView alloc] initWithFrame:(CGRect){0, 0, frame.size.width, frame.size.height - downHeight}];
        upView.backgroundColor = [UIColor clearColor];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(disMiss:)];
        [upView addGestureRecognizer:tap];
        
        //底部
        downView = [[UIView alloc] initWithFrame:(CGRect){0, frame.size.height - downHeight, frame.size.width, downHeight}];
        downView.backgroundColor = kColor(255, 255, 255, 0.9);
        
        //底部标题
        UIView *downTopView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, downTopHeight)];
        downTopView.backgroundColor = [UIColor clearColor];
        
        UILabel *tileLabel = [[UILabel alloc] initWithFrame:downTopView.frame];
        [tileLabel setBackgroundColor:[UIColor clearColor]];
        [tileLabel setTextAlignment:NSTextAlignmentCenter];
        [tileLabel setTextColor:kColor(54, 54, 54, 1)];
        tileLabel.font = [UIFont systemFontOfSize:17];
        tileLabel.text = title;
        
        UIButton *cancelBt = [UIButton buttonWithType:UIButtonTypeCustom];
        [cancelBt setFrame:CGRectMake(0, 0, 44, downTopHeight)];
        cancelBt.titleLabel.font = [UIFont systemFontOfSize:15];
        [cancelBt setTitle:@"取消" forState:UIControlStateNormal];
        [cancelBt setTitleColor:kTitleColor forState:UIControlStateNormal];
        [cancelBt addTarget:self action:@selector(removeView:) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *okBt = [UIButton buttonWithType:UIButtonTypeCustom];
        [okBt setFrame:CGRectMake(downTopView.frame.size.width - downTopHeight, 0, 44, downTopHeight)];
        okBt.titleLabel.font = [UIFont systemFontOfSize:15];
        [okBt setTitle:@"确定" forState:UIControlStateNormal];
        [okBt setTitleColor:kTitleColor forState:UIControlStateNormal];
        [okBt addTarget:self action:@selector(okView:) forControlEvents:UIControlEventTouchUpInside];
        
        _pickView = [[UIPickerView alloc] initWithFrame:(CGRect){0, downTopHeight, frame.size.width, downHeight - downTopHeight}];
        _pickView.backgroundColor = [UIColor clearColor];
        _pickView.dataSource = self;
        _pickView.delegate = self;
        _pickView.showsSelectionIndicator = YES;
        
        [downTopView addSubview:tileLabel];
        [downTopView addSubview:cancelBt];
        [downTopView addSubview:okBt];
        
        [downView addSubview:downTopView];
        [downView addSubview:_pickView];
        
        UIView *line = [[UIView alloc] initWithFrame:(CGRect){0, downTopView.frame.size.height, downView.frame.size.width, 0.5}];
        line.backgroundColor = [UIColor colorWithRed:0.839 green:0.839 blue:0.839 alpha:1];
        [downView addSubview:line];
        
        [self addSubview:upView];
        [self addSubview:downView];

    }
    return self;
}

- (void)disMiss:(UITapGestureRecognizer *)tap
{
    [self hide];
}

- (void)show:(UIView *)view
{
    [view addSubview:self];
    /*
    CATransition *animation = [CATransition animation];
    animation.fillMode = kCAFillModeBackwards;
    animation.type = kCATransitionPush;
    animation.subtype = kCATransitionFromBottom;
    animation.duration = 3.25;
    [downView.layer addAnimation:animation forKey:nil];
     */
}

- (void)hide
{
    [self removeFromSuperview];
}

- (void)okView:(id)sender
{
    [_delegate pickerViewConfirm:self];
    [self hide];
}

- (void)removeView:(id)sender
{
    [_delegate pickerViewCancel:self];
    [self hide];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return [self.dataSource numberOfComponentsInPickerView:self];
}
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.dataSource pickerView:self numberOfRowsInComponent:component];
}
//- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
//{
//    return [self.delegate pickerView:self titleForRow:row forComponent:component];
//}
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    return [_delegate pickerView:self widthForComponent:component];
}
- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return [_delegate pickerView:self rowHeightForComponent:component];
}
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *label = (UILabel *)view;
    if (!label) {
        label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = kColor(77, 77, 77, 1);
        label.font = [UIFont boldSystemFontOfSize:17];
    } else {
        if ([view isKindOfClass:[UILabel class]]) {
            label = (UILabel *)view;
        }
    }
    label.text = [self.delegate pickerView:self titleForRow:row forComponent:component];
    return label;
}
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    [self.delegate pickerView:self didSelectRow:row inComponent:component];
}

@end
