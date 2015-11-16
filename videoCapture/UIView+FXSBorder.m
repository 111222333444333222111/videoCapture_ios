//
//  UIView+FXSBorder.m
//  uhuo
//
//  Created by Mr.Sen on 14-6-12.
//  Copyright (c) 2014年 Fengxinsen. All rights reserved.
//

#import "UIView+FXSBorder.h"

@implementation UIView (FXSBorder)

- (void)cornerRadiusWithRadius:(CGFloat)radius
{
    self.clipsToBounds = YES;
    self.layer.cornerRadius = radius;
}

- (void)borderWithColor:(UIColor *)color Width:(CGFloat)width
{
    self.layer.borderWidth = width;
    self.layer.borderColor = color.CGColor;
}

- (void)shadowWithColor:(UIColor *)color Radius:(CGFloat)radius Offset:(CGSize)offset Opacity:(CGFloat)opacity
{
    self.layer.shadowPath =[UIBezierPath bezierPathWithRect:self.layer.bounds].CGPath;//解决阴影滑动卡顿
    self.layer.shadowColor = color.CGColor;
    self.layer.shadowRadius = radius;
    self.layer.shadowOffset = offset;
    self.layer.shadowOpacity = opacity;
}

@end
