//
//  JJZDrawingManager.h
//  DrawingWithFriends
//
//  Created by Ryan C. Payne on 6/9/16.
//  Copyright © 2016 BullittSystems, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class JJZDrawingManager;
@class JJZDrawingPath;

@protocol JJZDrawingManagerDelegate <NSObject>

- (void)drawingManager:(JJZDrawingManager *)drawingManager didReceiveDrawingPath:(JJZDrawingPath *)drawingPath;
- (void)drawingManagerDidClear:(JJZDrawingManager *)drawingManager;

@end

@interface JJZDrawingManager : NSObject

@property (nonatomic, weak) id <JJZDrawingManagerDelegate> delegate;
@property (nonatomic, readonly) NSArray<JJZDrawingPath *> *drawingPaths;

- (void)clearDrawing;
- (void)persistDrawingPath:(JJZDrawingPath *)drawingPath;

@end
