//
//  JJZDrawingPath.h
//  DrawingWithFriends
//
//  Created by Ryan C. Payne on 6/8/16.
//  Copyright © 2016 BullittSystems, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JJZPoint : NSObject

@property (nonatomic, readonly) CGFloat x;
@property (nonatomic, readonly) CGFloat y;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCGPoint:(CGPoint)point NS_DESIGNATED_INITIALIZER;

@end

@interface JJZDrawingPath : NSObject

@property (nonatomic, readonly) NSMutableArray<JJZPoint *> *points;
@property (nonatomic, readonly) UIColor *color;

+ (instancetype)drawingPathFromDictionary:(NSDictionary *)dictionary;

- (instancetype)initWithColor:(UIColor *)color;
- (instancetype)initWithPoints:(NSArray<JJZPoint*> *)points color:(UIColor *)color NS_DESIGNATED_INITIALIZER;

- (void)addPoint:(CGPoint)point;

- (NSDictionary *)dictionaryRepresentation;
@end


