//
//  XJoyStick.m
//  Messi-iOS
//
//  Created by canoe on 2019/4/8.
//  Copyright © 2019 . All rights reserved.
//

#import "XJoyStick.h"

@interface XJoyStick ()

@property(nonatomic, strong) UIImageView *bgView;       //背景图片
@property(nonatomic, strong) UIImageView *stickView;    //按下图片
@property (nonatomic, assign) CGFloat stickMargin;
@property(nonatomic, assign) CGPoint deltaFactor;       //偏移量
@property(nonatomic, assign) BOOL isTouching;           //是否移动
@property(nonatomic, strong) NSTimer *timer;

@end


@implementation XJoyStick

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSubViews];
    }
    return self;
}

- (void)setupSubViews {
    _alphaIdle = 0.75;
    _alphaTouch = 1.0;
    _inteval = 0.01;
    _handleDiameter = floor(self.frame.size.width * 0.6);
    _stickMargin = 0.0;
    
    self.alpha = _alphaIdle;
    self.backgroundColor = [UIColor clearColor];
    self.deltaFactor = CGPointMake(0, 0);
    
    self.bgView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.bgView.image = [UIImage imageNamed:@"jSubstrate"];
    [self addSubview:self.bgView];
    
    self.stickView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _handleDiameter, _handleDiameter)];
    self.stickView.image = [UIImage imageNamed:@"jStick"];
    [self addSubview:self.stickView];
    self.stickView.center = self.bgView.center;
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panHandler:)];
    [pan setMaximumNumberOfTouches:1];
    [self addGestureRecognizer:pan];
    
}


#pragma mark - Properties

- (void)setBGImage:(UIImage *)bgImage
{
    _bgView.image = bgImage;
}

- (void)setStickImage:(UIImage *)stickImage
{
    _stickView.image = stickImage;
}

- (void)setInteval:(CGFloat)newValue {
    _inteval = newValue;
    if (_timer) {
        [self stopUpdating];
        [self beginUpdating];
    }
}

- (void)setAlphaIdle:(CGFloat)newValue {
    _alphaIdle = newValue;
    self.alpha = _isTouching?_alphaTouch:_alphaIdle;
}

- (void)setAlphaTouch:(CGFloat)newValue {
    _alphaTouch = newValue;
    self.alpha = _isTouching?_alphaTouch:_alphaIdle;
}

#pragma mark - Gesture Handler

- (void)panHandler:(UIPanGestureRecognizer *)pan {
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
        {
            _isTouching = YES;
            self.alpha = _alphaTouch;
            
            CGPoint position = [pan locationInView:self];
            CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
            CGFloat radius = self.bounds.size.width * 0.5 - _stickMargin;
            
            CGFloat deltaX = position.x - center.x;
            CGFloat deltaY = position.y - center.y;
            //圆外
            if (powf(deltaX, 2) + powf(deltaY, 2) > powf(radius, 2)) {
                CGFloat angle = atan(deltaY / deltaX);
                CGPoint oldOffset = CGPointMake(deltaX, deltaY);
                CGPoint newOffset = CGPointMake(radius * cos(angle), radius * sin(angle));
                if ([self sgnValue:newOffset.x] != [self sgnValue:oldOffset.x])
                    newOffset.x = -newOffset.x;
                if ([self sgnValue:newOffset.y] != [self sgnValue:oldOffset.y])
                    newOffset.y = -newOffset.y;
                position = CGPointMake(center.x + newOffset.x, center.y + newOffset.y);
            }
            
            self.stickView.center = position;
            
            _deltaFactor.x = (position.x - center.x)/ radius;
            _deltaFactor.y = (center.y - position.y)/ radius;
            
            if (pan.state == UIGestureRecognizerStateBegan) {
                if ([self.delegate respondsToSelector:@selector(joystick:didBegin:)]) {
                    [self.delegate joystick:self didBegin:_deltaFactor];
                }
            }
            [self beginUpdating];
        }
            break;
        case UIGestureRecognizerStatePossible:
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        default:
        {
            _isTouching = NO;
            self.alpha = _alphaIdle;
            
            CGPoint selfCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
            self.stickView.center = selfCenter;
            
            [self stopUpdating];
            
            if ([self.delegate respondsToSelector:@selector(joystick:didEnd:)]) {
                [self.delegate joystick:self didEnd:_deltaFactor];
            }
            
            _deltaFactor = CGPointZero;
        }
            break;
    }
}

//Sgn 函数 返回一个 Variant (Integer)，指出参数的正负号。
- (NSInteger)sgnValue:(CGFloat)value
{
    if (value == 0) {
        return 0;
    }else if (value > 0){
        return 1;
    }else{
        return -1;
    }
}

#pragma mark - Updates

- (void)timerHandler {
    if ([self.delegate respondsToSelector:@selector(joystick:didUpdate:)]) {
        [self.delegate joystick:self didUpdate:_deltaFactor];
    }
}

- (void)beginUpdating {
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:_inteval target:self selector:@selector(timerHandler) userInfo:nil repeats:YES];
    }
}

- (void)stopUpdating {
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}


@end
