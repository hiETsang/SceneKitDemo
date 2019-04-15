//
//  XJoyStick.h
//  Messi-iOS
//
//  Created by canoe on 2019/4/8.
//  Copyright © 2019 . All rights reserved.
//

#import <UIKit/UIKit.h>

@class XJoyStick;
@protocol XJoystickDelegate <NSObject>
@optional
- (void)joystick:(XJoyStick *)aJoystick didBegin:(CGPoint)deltaFactor;
- (void)joystick:(XJoyStick *)aJoystick didUpdate:(CGPoint)deltaFactor;
- (void)joystick:(XJoyStick *)aJoystick didEnd:(CGPoint)deltaFactor;
@end


@interface XJoyStick : UIView
@property(nonatomic, weak) id<XJoystickDelegate> delegate;
@property (nonatomic, assign) CGFloat alphaIdle;    //空闲时的透明度
@property (nonatomic, assign) CGFloat alphaTouch;   //按压时的透明度
@property(nonatomic, assign) CGFloat handleDiameter;//操控点的直径
@property (nonatomic, assign) CGFloat inteval;      //回调时间间隔

- (void)setStickImage:(UIImage *)stickImage;
- (void)setBGImage:(UIImage *)bgImage;

@end


