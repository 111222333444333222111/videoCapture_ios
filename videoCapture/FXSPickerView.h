//
//  KDPickerView.h
//  PhoneGuard
//
//  Created by Mr.Sen on 14-4-18.
//  Copyright (c) 2014年 炎翔通信. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FXSPickerViewDelegate;
@protocol FXSPickerViewDataSource;

@interface FXSPickerView : UIView<UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, weak) id<FXSPickerViewDelegate> delegate;
@property (nonatomic, weak) id<FXSPickerViewDataSource> dataSource;

@property (nonatomic, strong, readonly) UIPickerView *pickView;

- (id)initWithFrame:(CGRect)frame title:(NSString *)title;

- (void)show:(UIView *)view;

- (void)hide;

@end

@protocol FXSPickerViewDelegate <NSObject>

- (CGFloat)pickerView:(FXSPickerView *)pickerView widthForComponent:(NSInteger)component;

- (CGFloat)pickerView:(FXSPickerView *)pickerView rowHeightForComponent:(NSInteger)component;

- (NSString *)pickerView:(FXSPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component;

- (void)pickerView:(FXSPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component;

@optional
- (void)pickerViewConfirm:(FXSPickerView *)pickerView;
- (void)pickerViewCancel:(FXSPickerView *)pickerView;

@end

@protocol FXSPickerViewDataSource <NSObject>

- (NSInteger)numberOfComponentsInPickerView:(FXSPickerView *)pickerView;

- (NSInteger)pickerView:(FXSPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component;

@end