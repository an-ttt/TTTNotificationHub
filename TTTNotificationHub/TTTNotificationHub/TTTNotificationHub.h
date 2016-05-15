//
//  TTTNotificationHub.h
//  TTTNotificationHub
//
//  Created by Richard Kim on 9/30/14.
//  Copyright (c) 2014 Richard Kim. All rights reserved.
//

/*
 
 Copyright (c) 2014 Choong-Won Richard Kim <cwrichardkim@gmail.com>
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is furnished
 to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

//  QQButton.h
//  QQBtn
//
//  Created by MacBook on 15/6/25.
//  Copyright (c) 2015年 维尼的小熊. All rights reserved.
//


//
//  TTTNotificationHub.h
//  TTTNotificationHub
//
//  Created by an_ttt on 03/27/16.
//  Copyright (c) 2016 an_ttt. All rights reserved.
//




#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 *  The default diameter of the notification hub view.
 */
FOUNDATION_EXPORT CGFloat const TTTNotificationHubDefaultDiameter;

@interface TTTNotificationHub : NSObject

//%%% setup
- (id)initWithView:(UIView *)view scale:(CGFloat)scale offset:(CGPoint)offset maxInstance:(NSUInteger)maxInstance;

//%%% adjustment methods
- (void)setView:(UIView *)view andCount:(NSUInteger)startCount;

@property (nonatomic, assign) BOOL canPan;
@property (nonatomic, assign) CGPoint offset;
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, strong) UIFont *countLabelFont;
@property (nonatomic, assign) NSUInteger count;

//%%% changing the count
- (void)setCountAndCheckZero:(NSUInteger)amount;


//%%% hiding / showing the count
- (void)hideCount;
- (void)showCount;

//%%% animations
- (void)pop;
- (void)blink;
- (void)bump;


typedef void (^TTTHubDestoryBlock)();
@property (nonatomic, copy) TTTHubDestoryBlock destoryBlock;

@property (nonatomic)UIView *containerView;
@property (nonatomic)UIView *hubView;

@end
