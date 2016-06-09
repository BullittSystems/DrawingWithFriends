//
//  JJZCanvasView.h
//  DrawingWithFriends
//
//  Created by Ryan C. Payne on 6/8/16.
//  Copyright © 2016 BullittSystems, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JJZCanvasView;
@class JJZDrawingPath;

@protocol JJZCanvasViewDelegate <NSObject>
- (void)canvasView:(JJZCanvasView *)canvasView didFinishDrawingPath:(JJZDrawingPath *)drawingPath;
@end


@interface JJZCanvasView : UIView

@property (nonatomic, weak) id <JJZCanvasViewDelegate> delegate;

@property (nonatomic, strong) UIColor *currentColor;

- (void)addDrawingPath:(JJZDrawingPath *)drawingPath;
- (void)clear;

@end
