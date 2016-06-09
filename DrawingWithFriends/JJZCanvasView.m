//
//  JJZCanvasView.m
//  DrawingWithFriends
//
//  Created by Ryan C. Payne on 6/8/16.
//  Copyright © 2016 BullittSystems, Inc. All rights reserved.
//

#import "JJZCanvasView.h"
#import "JJZDrawingPath.h"

@interface JJZCanvasView()

// Draw paths from Firebase
@property (nonatomic, strong) NSMutableArray *remotePaths;

// Locally drawn paths
@property (nonatomic, strong) JJZDrawingPath *currentPath;
@property (nonatomic, strong) UITouch *currentTouch;

@end

@implementation JJZCanvasView

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
    self.remotePaths = [NSMutableArray array];
    self.backgroundColor = [UIColor whiteColor];
    self.currentColor = [UIColor blackColor];
}

#pragma mark - View Drawing
- (void)drawPath:(JJZDrawingPath *)path withContext:(CGContextRef)context
{
    if (path.points.count > 1) {
        CGContextBeginPath(context);
        CGContextSetStrokeColorWithColor(context, path.color.CGColor);

        JJZPoint *point = path.points[0];
        CGContextMoveToPoint(context, point.x, point.y);

        for (NSUInteger i = 0; i < path.points.count; i++) {
            JJZPoint *point = path.points[i];
            CGContextAddLineToPoint(context, point.x, point.y);
        }

        CGContextDrawPath(context, kCGPathStroke);
    }
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 0.5f);

    for (JJZDrawingPath *path in self.remotePaths) {
        [self drawPath:path withContext:context];
    }

    if (self.currentPath != nil) {
        [self drawPath:self.currentPath withContext:context];
    }
}

#pragma mark - Remote Drawing Methods
- (void)addDrawingPath:(JJZDrawingPath *)drawingPath {
    [self.remotePaths addObject:drawingPath];
    [self setNeedsDisplay];
}

#pragma mark - Local Drawing Methods
- (void)clear {
    [self.remotePaths removeAllObjects];
    [self setNeedsDisplay];

    [self.delegate didClearCanvasView:self];
}

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    if (self.currentPath == nil) {
        self.currentTouch = [touches anyObject];
        self.currentPath = [[JJZDrawingPath alloc] initWithColor:self.currentColor];

        CGPoint touchPoint = [self.currentTouch locationInView:self];
        [self.currentPath addPoint:touchPoint];

        [self setNeedsDisplay];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.currentPath != nil) {
        for (UITouch *touch in touches) {
            if (self.currentTouch == touch) {
                CGPoint touchPoint = [self.currentTouch locationInView:self];
                [self.currentPath addPoint:touchPoint];
                [self setNeedsDisplay];
            }
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.currentPath != nil) {
        for (UITouch *touch in touches) {
            if (self.currentTouch == touch) {
                self.currentPath = nil;
                self.currentTouch = nil;
                [self setNeedsDisplay];
            }
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.currentPath != nil) {
        for (UITouch *touch in touches) {
            if (self.currentTouch == touch) {
                [self.remotePaths addObject:self.currentPath];

                // Notify the delegate so this can be sent to our friends
                [self.delegate canvasView:self didFinishDrawingPath:self.currentPath];

                // reset drawing state
                self.currentPath = nil;
                self.currentTouch = nil;
            }
        }
    }
}

@end
