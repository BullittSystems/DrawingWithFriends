//
//  JJZDraggableFloatyView.m
//  DrawingWithFriends
//
//  Created by Ryan C. Payne on 6/8/16.
//  Copyright © 2016 BullittSystems, Inc. All rights reserved.
//

#import "JJZDraggableFloatyView.h"

@interface JJZDraggableFloatyView ()

@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;

@end

@implementation JJZDraggableFloatyView

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self performSetup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self performSetup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        [self performSetup];
    }
    return self;
}

- (void)performSetup
{
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(2, 2);
    self.layer.shadowRadius = 3.5;
    self.layer.shadowOpacity = 0.4;

    [self prepareGestures];
}

#pragma mark - View Preperations

- (void)prepareGestures
{
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panning:)];
    [self.panGesture setMinimumNumberOfTouches:1];
    [self.panGesture setMaximumNumberOfTouches:1];
    [self addGestureRecognizer:self.panGesture];
}

#pragma mark - Panning

- (void)panning:(UIPanGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
    }
    else if (([recognizer state] == UIGestureRecognizerStateEnded) ||
             ([recognizer state] == UIGestureRecognizerStateFailed))
    {
    }
    else
    {
        CGPoint translation = [recognizer translationInView:self];

        typeof(self) __weak weakSelf = self;
        [UIView animateWithDuration:0.1 animations:^{
            typeof(self) __strong strongSelf = weakSelf;
            recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                                 recognizer.view.center.y + translation.y);
            [recognizer setTranslation:CGPointMake(0, 0) inView:strongSelf];
        }];
    }
}

@end
