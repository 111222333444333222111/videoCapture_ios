//
//  UIView+FXSBorder.h
//  uhuo
//
//  Created by Mr.Sen on 14-6-12.
//  Copyright (c) 2014年 Fengxinsen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (FXSBorder)

/**
 *  设置圆角
 *
 *  @param radius 圆角半径
 */
- (void)cornerRadiusWithRadius:(CGFloat)radius;

/**
 *  设置描边
 *
 *  @param color 描边颜色
 *  @param width 描边宽度
 */
- (void)borderWithColor:(UIColor *)color Width:(CGFloat)width;

/**
 *  设置阴影
 *
 *  @param color   阴影颜色
 *  @param radius  阴影半径
 *  @param offset  阴影偏移,x向右偏移，y向下偏移，默认(0, -3),这个跟shadowRadius
 *  @param opacity 阴影透明度
 */
- (void)shadowWithColor:(UIColor *)color Radius:(CGFloat)radius Offset:(CGSize)offset Opacity:(CGFloat)opacity;

@end
