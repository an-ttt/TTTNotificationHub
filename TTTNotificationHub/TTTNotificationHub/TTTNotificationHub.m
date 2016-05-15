//
//  TTTNotificationHub.m
//  TTTNotificationHub
//
//  Created by Richard Kim on 9/30/14.
//  Copyright (c) 2014 Richard Kim. All rights reserved.
//


//
//  TTTNotificationHub.m
//  TTTNotificationHub
//
//  Created by an_ttt on 03/27/16.
//  Copyright (c) 2016 an_ttt. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "TTTNotificationHub.h"
#import "TTTNotificationHub-swift.h"


//%%% default diameter
#define TTTNotificationHubDefaultDiameter (30*_scale)
static CGFloat const kCountMagnitudeAdaptationRatio = 0.3;
//%%% pop values
static CGFloat const kPopStartRatio = .85;
static CGFloat const kPopOutRatio = 1.05;
static CGFloat const kPopInRatio = .95;

//%%% blink values
static CGFloat const kBlinkDuration = 0.1;
static CGFloat const kBlinkAlpha = 0.1;

//%%% bump values
static CGFloat const kFirstBumpDistance = 8.0;
static CGFloat const kBumpTimeSeconds = 0.13;
static CGFloat const SECOND_BUMP_DIST = 4.0;
static CGFloat const kBumpTimeSeconds2 = 0.1;


@interface RKView : UIView
@property (nonatomic) BOOL isUserChangingBackgroundColor;
@end

@implementation RKView

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    if (self.isUserChangingBackgroundColor) {
        super.backgroundColor = backgroundColor;
        self.isUserChangingBackgroundColor = NO;
    }
}

@end

@interface TTTNotificationHub()

@property (nonatomic, strong) RKView *shadowView;

/** 绘制不规则图形 */
@property (nonatomic, strong) CAShapeLayer *shapeLayer;
@property (nonatomic, assign) CGFloat maxDistance;


@end

@implementation TTTNotificationHub {
    int curOrderMagnitude;
    UILabel *countLabel;
    RKView *redCircle;
    CGPoint initialCenter;
    CGRect baseFrame;
    CGRect initialFrame;
    BOOL isIndeterminateMode;
}

#pragma mark - SETUP


- (id)initWithView:(UIView *)view scale:(CGFloat)scale offset:(CGPoint)offset maxInstance:(NSUInteger)maxInstance
{
    self = [super init];
    if (!self)
        return nil;
    
    self.offset = offset;
    self.scale = scale;
    self.canPan = YES;
    
    self.maxDistance = maxInstance;
    [self setView:view andCount:0];
    
    return self;
}


//%%% give this a view and an initial count (0 hides the notification circle)
// and it will make a hub for you
- (void)setView:(UIView *)view andCount:(NSUInteger)startCount
{
    if (self.hubView && self.shadowView) {
        return;
    }
    
    curOrderMagnitude = 0;
    self.containerView = view;
    self.containerView.userInteractionEnabled = YES;
    
    [self setupHubViewWithParentFrame:view.frame startCount:startCount];
    
    [self setupShadowView];
    
    [self checkZeroWithBoom:NO];
    
}

-(void)setupShadowView
{
    if (!_shadowView) {
        _shadowView = [[RKView alloc]init];
        [self.containerView addSubview:_shadowView];
        [self.containerView sendSubviewToBack:_shadowView];
    }
    
    _shadowView.isUserChangingBackgroundColor = YES;
    _shadowView.backgroundColor = [redCircle backgroundColor];
    
    CGRect frame = self.hubView.frame;
    _shadowView.bounds = CGRectMake(0.0f, 0.0f, frame.size.width * 2 / 3, frame.size.height * 2 / 3);
    _shadowView.center = self.hubView.center;
    _shadowView.backgroundColor = [UIColor blueColor];
    _shadowView.layer.cornerRadius = _shadowView.bounds.size.width / 2;
    
    
}

-(void)setupHubViewWithParentFrame:(CGRect)frame startCount:(NSUInteger)startCount
{
    
    UIView *hubView = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width- (TTTNotificationHubDefaultDiameter*2/3) + _offset.x, -TTTNotificationHubDefaultDiameter/3 + _offset.y, TTTNotificationHubDefaultDiameter, TTTNotificationHubDefaultDiameter)];
    
    isIndeterminateMode = NO;
    
    redCircle = [[RKView alloc]init];
    redCircle.userInteractionEnabled = YES;
    redCircle.isUserChangingBackgroundColor = YES;
    redCircle.backgroundColor = [UIColor redColor];
    
    countLabel = [[UILabel alloc]initWithFrame:redCircle.frame];
    countLabel.userInteractionEnabled = YES;
    self.count = startCount;
    [countLabel setTextAlignment:NSTextAlignmentCenter];
    countLabel.textColor = [UIColor whiteColor];
    countLabel.backgroundColor = [UIColor clearColor];
    
    [self setCircleAtFrame:CGRectMake(0.0f, 0.0f, TTTNotificationHubDefaultDiameter, TTTNotificationHubDefaultDiameter)];
    
    [hubView addSubview:redCircle];
    [hubView addSubview:countLabel];
    self.hubView = hubView;
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panHub:)];
    [self.hubView addGestureRecognizer:pan];
    
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(didClickHubView)];
    [self.hubView addGestureRecognizer:singleTap];
    
    //self.hubView.backgroundColor = [UIColor purpleColor];
    [self.containerView addSubview:hubView];
}

//%%% set the frame of the notification circle relative to the button
- (void)setCircleAtFrame:(CGRect)frame
{
    [redCircle setFrame:frame];
    initialCenter = CGPointMake(frame.origin.x+frame.size.width/2, frame.origin.y+frame.size.height/2);
    baseFrame = frame;
    initialFrame = frame;
    countLabel.frame = redCircle.frame;
    redCircle.layer.cornerRadius = frame.size.height/2;
    [countLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:frame.size.width/2]];
    [self expandToFitLargerDigits];
}

//%%% moves the circle by x amount on the x axis and y amount on the y axis
- (void)moveCircleByX:(CGFloat)x Y:(CGFloat)y
{
    CGRect frame = redCircle.frame;
    frame.origin.x += x;
    frame.origin.y += y;
    [self setCircleAtFrame:frame];
}

//%%% changes the size of the circle. setting a scale of 1 has no effect
- (void)scaleCircleSizeBy:(CGFloat)scale
{
    CGRect fr = initialFrame;
    CGFloat width = fr.size.width * scale;
    CGFloat height = fr.size.height * scale;
    CGFloat wdiff = (fr.size.width - width) / 2;
    CGFloat hdiff = (fr.size.height - height) / 2;
    
    CGRect frame = CGRectMake(fr.origin.x + wdiff, fr.origin.y + hdiff, width, height);
    [self setCircleAtFrame:frame];
}

//%%% change the color of the notification circle
- (void)setCircleColor:(UIColor*)circleColor labelColor:(UIColor*)labelColor
{
    redCircle.isUserChangingBackgroundColor = YES;
    redCircle.backgroundColor = circleColor;
    [countLabel setTextColor:labelColor];
}

- (void)hideCount
{
    countLabel.hidden = YES;
    isIndeterminateMode = YES;
}

- (void)showCount
{
    isIndeterminateMode = NO;
    [self checkZeroWithBoom:NO];
}

#pragma mark - ATTRIBUTES

//%%% increases count by 1
- (void)increment
{
    [self incrementBy:1];
}

//%%% increases count by amount
- (void)incrementBy:(NSUInteger)amount
{
    if (!self.hubView) {
        [self setView:self.containerView andCount:amount];
        return;
    }
    
    self.count += amount;
}

//%%% decreases count
- (void)decrement
{
    [self decrementBy:1];
}

//%%% decreases count by amount
- (void)decrementBy:(NSUInteger)amount
{
    if (amount >= self.count) {
        self.count = 0;
        return;
    }
    self.count -= amount;
}

- (void)setCountAndCheckZero:(NSUInteger)amount
{
    if (self.count == amount) {
        return;
    }
    
    if (!self.hubView) {
        [self setView:self.containerView andCount:amount];
        return;
    }
    
    
    self.count = amount;
    
    if (amount == 0) {
        [self checkZeroWithBoom:YES];
    }
}

//%%% set the count yourself
- (void)setCount:(NSUInteger)newCount
{
    _count = newCount;
    countLabel.text = [NSString stringWithFormat:@"%@", @(self.count)];
    
}

//%% set the font of the label
- (void)setCountLabelFont:(UIFont *)font
{
    [countLabel setFont:[UIFont fontWithName:font.fontName size:redCircle.frame.size.width/2]];
}

- (UIFont *)countLabelFont
{
    return countLabel.font;
}

#pragma mark - ANIMATION

//%%% animation that resembles facebook's pop
- (void)pop
{
    const float height = baseFrame.size.height;
    const float width = baseFrame.size.width;
    const float pop_start_h = height * kPopStartRatio;
    const float pop_start_w = width * kPopStartRatio;
    const float time_start = 0.05;
    const float pop_out_h = height * kPopOutRatio;
    const float pop_out_w = width * kPopOutRatio;
    const float time_out = .2;
    const float pop_in_h = height * kPopInRatio;
    const float pop_in_w = width * kPopInRatio;
    const float time_in = .05;
    const float pop_end_h = height;
    const float pop_end_w = width;
    const float time_end = 0.05;
    
    CABasicAnimation *startSize = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
    startSize.duration = time_start;
    startSize.beginTime = 0;
    startSize.fromValue = @(pop_end_h / 2);
    startSize.toValue = @(pop_start_h / 2);
    startSize.removedOnCompletion = FALSE;
    
    CABasicAnimation *outSize = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
    outSize.duration = time_out;
    outSize.beginTime = time_start;
    outSize.fromValue = startSize.toValue;
    outSize.toValue = @(pop_out_h / 2);
    outSize.removedOnCompletion = FALSE;
    
    CABasicAnimation *inSize = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
    inSize.duration = time_in;
    inSize.beginTime = time_start+time_out;
    inSize.fromValue = outSize.toValue;
    inSize.toValue = @(pop_in_h / 2);
    inSize.removedOnCompletion = FALSE;
    
    CABasicAnimation *endSize = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
    endSize.duration = time_end;
    endSize.beginTime = time_in+time_out+time_start;
    endSize.fromValue = inSize.toValue;
    endSize.toValue = @(pop_end_h / 2);
    endSize.removedOnCompletion = FALSE;
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    [group setDuration: time_start+time_out+time_in+time_end];
    [group setAnimations:@[startSize, outSize, inSize, endSize]];
    
    [redCircle.layer addAnimation:group forKey:nil];
    
    [UIView animateWithDuration:time_start animations:^{
        CGRect frame = redCircle.frame;
        CGPoint center = redCircle.center;
        frame.size.height = pop_start_h;
        frame.size.width = pop_start_w;
        redCircle.frame = frame;
        redCircle.center = center;
    }completion:^(BOOL complete){
        [UIView animateWithDuration:time_out animations:^{
            CGRect frame = redCircle.frame;
            CGPoint center = redCircle.center;
            frame.size.height = pop_out_h;
            frame.size.width = pop_out_w;
            redCircle.frame = frame;
            redCircle.center = center;
        }completion:^(BOOL complete){
            [UIView animateWithDuration:time_in animations:^{
                CGRect frame = redCircle.frame;
                CGPoint center = redCircle.center;
                frame.size.height = pop_in_h;
                frame.size.width = pop_in_w;
                redCircle.frame = frame;
                redCircle.center = center;
            }completion:^(BOOL complete){
                [UIView animateWithDuration:time_end animations:^{
                    CGRect frame = redCircle.frame;
                    CGPoint center = redCircle.center;
                    frame.size.height = pop_end_h;
                    frame.size.width = pop_end_w;
                    redCircle.frame = frame;
                    redCircle.center = center;
                }];
            }];
        }];
    }];
}

//%%% animation that flashes on an off
- (void)blink
{
    [self setHubAlpha:kBlinkAlpha];
    
    [UIView animateWithDuration:kBlinkDuration animations:^{
        [self setHubAlpha:1];
    }completion:^(BOOL complete){
        [UIView animateWithDuration:kBlinkDuration animations:^{
            [self setHubAlpha:kBlinkAlpha];
        }completion:^(BOOL complete){
            [UIView animateWithDuration:kBlinkDuration animations:^{
                [self setHubAlpha:1];
            }];
        }];
    }];
}

//%%% animation that jumps similar to OSX dock icons
- (void)bump
{
    if (!CGPointEqualToPoint(initialCenter,redCircle.center)) {
        //%%% canel previous animation
    }
    
    [self bumpCenterY:0];
    [UIView animateWithDuration:kBumpTimeSeconds animations:^{
        [self bumpCenterY:kFirstBumpDistance];
    }completion:^(BOOL complete){
        [UIView animateWithDuration:kBumpTimeSeconds animations:^{
            [self bumpCenterY:0];
        }completion:^(BOOL complete){
            [UIView animateWithDuration:kBumpTimeSeconds2 animations:^{
                [self bumpCenterY:SECOND_BUMP_DIST];
            }completion:^(BOOL complete){
                [UIView animateWithDuration:kBumpTimeSeconds2 animations:^{
                    [self bumpCenterY:0];
                }];
            }];
        }];
    }];
}

#pragma mark - HELPERS

//%%% changes the Y origin of the notification circle
- (void)bumpCenterY:(float)yVal
{
    CGPoint center = redCircle.center;
    center.y = initialCenter.y-yVal;
    redCircle.center = center;
    countLabel.center = center;
}

- (void)setHubAlpha:(float)alpha
{
    redCircle.alpha = alpha;
    countLabel.alpha = alpha;
}

//%%% hides the notification if the value is 0
- (void)checkZeroWithBoom:(BOOL)isBoom
{
    if (self.count <= 0) {
        redCircle.hidden = YES;
        countLabel.hidden = YES;
        self.shadowView.hidden = YES;
        
        //播放销毁动画
        if (isBoom) {
            [self.hubView boom];
        }
        else
            [self.hubView removeFromSuperview];
        
        self.hubView = nil;
        
        
        [self.shapeLayer removeFromSuperlayer];
        self.shapeLayer = nil;
        
        [self.shadowView removeFromSuperview];
        self.shadowView = nil;
        
        if (_destoryBlock) {
            _destoryBlock();
        }
        
    } else {
        redCircle.hidden = NO;
        self.shadowView.hidden = NO;
        if (!isIndeterminateMode) {
            countLabel.hidden = NO;
        }
    }
}

- (void)expandToFitLargerDigits {
    int orderOfMagnitude = log10((double)self.count);
    orderOfMagnitude = (orderOfMagnitude >= 2) ? orderOfMagnitude : 1;
    CGRect frame = initialFrame;
    frame.size.width = initialFrame.size.width * (1 + kCountMagnitudeAdaptationRatio * (orderOfMagnitude - 1));
    frame.origin.x = initialFrame.origin.x - (frame.size.width - initialFrame.size.width) / 2;
    
    [redCircle setFrame:frame];
    initialCenter = CGPointMake(frame.origin.x+frame.size.width/2, frame.origin.y+frame.size.height/2);
    baseFrame = frame;
    countLabel.frame = redCircle.frame;
    curOrderMagnitude = orderOfMagnitude;
}

#pragma mark QQButton

- (CAShapeLayer *)shapeLayer
{
    if (!_shapeLayer) {
        _shapeLayer = [CAShapeLayer layer];
        _shapeLayer.fillColor = self.shadowView.backgroundColor.CGColor;
        [self.containerView.layer insertSublayer:_shapeLayer below:self.hubView.layer];
    }
    
    return _shapeLayer;
}



#pragma mark - 手势
- (void)didClickHubView
{
    NSLog(@"didClickHubView");
}

- (void)panHub:(UIPanGestureRecognizer *)pan
{
    if (!_canPan) {
        return;
    }
    
    CGPoint panPoint = [pan translationInView:self.hubView];
    
    CGPoint changeCenter = self.hubView.center;
    changeCenter.x += panPoint.x;
    changeCenter.y += panPoint.y;
    self.hubView.center = changeCenter;
    [pan setTranslation:CGPointZero inView:self.hubView];
    
    //俩个圆的中心点之间的距离
    CGFloat dist = [self pointToPoitnDistanceWithPoint:self.hubView.center potintB:self.shadowView.center];
    
    CGRect frame = self.hubView.frame;
    
    if (dist < _maxDistance) {
        self.shadowView.hidden = NO;
        CGFloat cornerRadius = (frame.size.height > frame.size.width ? frame.size.height / 2 : frame.size.height / 2);
        CGFloat smallCrecleRadius = cornerRadius - dist / 10;
        _shadowView.bounds = CGRectMake(0, 0, smallCrecleRadius * (2 - 0.5), smallCrecleRadius * (2 - 0.5));
        _shadowView.layer.cornerRadius = _shadowView.bounds.size.width / 2;
        
        if (_shadowView.hidden == NO && dist > 0) {
            //画不规则矩形
            self.shapeLayer.path = [self pathWithBigCirCleView:self.hubView shadowView:self.shadowView].CGPath;
        }
    } else {
        
        self.shadowView.hidden = YES;
        
        [self.shapeLayer removeFromSuperlayer];
        self.shapeLayer = nil;
    }
    
    if (pan.state == UIGestureRecognizerStateEnded) {
        
        if (dist > _maxDistance) {
            
            [self setCountAndCheckZero:0];
            
        } else {
            
            [self.shapeLayer removeFromSuperlayer];
            self.shapeLayer = nil;
            
            [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.2 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.hubView.center = self.shadowView.center;
            } completion:^(BOOL finished) {
                self.shadowView.hidden = NO;
            }];
        }
    }
}

#pragma mark - 不规则路径
- (UIBezierPath *)pathWithBigCirCleView:(UIView *)bigCirCleView  shadowView:(UIView *)shadowView
{
    CGPoint bigCenter = bigCirCleView.center;
    CGFloat x2 = bigCenter.x;
    CGFloat y2 = bigCenter.y;
    CGFloat r2 = bigCirCleView.bounds.size.width / 2;
    
    CGPoint smallCenter = shadowView.center;
    CGFloat x1 = smallCenter.x;
    CGFloat y1 = smallCenter.y;
    CGFloat r1 = shadowView.bounds.size.width / 2;
    
    // 获取圆心距离
    CGFloat d = [self pointToPoitnDistanceWithPoint:bigCirCleView.center potintB:shadowView.center];
    CGFloat sinθ = (x2 - x1) / d;
    CGFloat cosθ = (y2 - y1) / d;
    
    // 坐标系基于父控件
    CGPoint pointA = CGPointMake(x1 - r1 * cosθ , y1 + r1 * sinθ);
    CGPoint pointB = CGPointMake(x1 + r1 * cosθ , y1 - r1 * sinθ);
    CGPoint pointC = CGPointMake(x2 + r2 * cosθ , y2 - r2 * sinθ);
    CGPoint pointD = CGPointMake(x2 - r2 * cosθ , y2 + r2 * sinθ);
    CGPoint pointO = CGPointMake(pointA.x + d / 2 * sinθ , pointA.y + d / 2 * cosθ);
    CGPoint pointP = CGPointMake(pointB.x + d / 2 * sinθ , pointB.y + d / 2 * cosθ);
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    // A
    [path moveToPoint:pointA];
    // AB
    [path addLineToPoint:pointB];
    // 绘制BC曲线
    [path addQuadCurveToPoint:pointC controlPoint:pointP];
    // CD
    [path addLineToPoint:pointD];
    // 绘制DA曲线
    [path addQuadCurveToPoint:pointA controlPoint:pointO];
    
    return path;
}

#pragma mark - 俩个圆心之间的距离
- (CGFloat)pointToPoitnDistanceWithPoint:(CGPoint)pointA potintB:(CGPoint)pointB
{
    CGFloat offestX = pointA.x - pointB.x;
    CGFloat offestY = pointA.y - pointB.y;
    CGFloat dist = sqrtf(offestX * offestX + offestY * offestY);
    
    return dist;
}


@end

