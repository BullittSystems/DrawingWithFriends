//
//  JJZDrawingPath.m
//  DrawingWithFriends
//
//  Created by Ryan C. Payne on 6/8/16.
//  Copyright © 2016 BullittSystems, Inc. All rights reserved.
//

#import "JJZDrawingPath.h"
#import "UIColor+Hex.h"

static NSString *const kJJZPointXKey = @"x";
static NSString *const kJJZPointYKey = @"y";

static NSString *const kJJZDrawingPathColorKey = @"color";
static NSString *const kJJZDrawingPathPointsKey = @"points";

@interface JJZPoint()
@property (nonatomic, assign) CGPoint point;
@end

@implementation JJZPoint

// Even though we marked this initializer as NS_UNAVAILABLE, we want it to fail fast during development
// if somebody accidentally does `[<Class> new]`.
- (instancetype)init
{
    self = nil;

    NSException *exception = [NSException exceptionWithName:@"JJZPointInitializationException" reason:@"JJZPoint requires the use of the parameterized initializer." userInfo:nil];
    [exception raise];

    return self;
}

- (instancetype)initWithCGPoint:(CGPoint)point {
    self = [super init];

    if (self) {
        _point = point;
    }

    return self;
}

+ (instancetype)pointFromDictionary:(NSDictionary *)dictionary {

    if (![dictionary[kJJZPointXKey] isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    if (![dictionary[kJJZPointYKey] isKindOfClass:[NSNumber class]]) {
        return nil;
    }

    CGPoint point = CGPointMake([dictionary[kJJZPointXKey] floatValue], [dictionary[kJJZPointYKey] floatValue]);
    return [[JJZPoint alloc] initWithCGPoint:point];
}

- (NSDictionary *)dictionaryRepresentation {
    return @{ kJJZPointXKey: [NSNumber numberWithInteger:self.x], kJJZPointYKey: [NSNumber numberWithInteger:self.y] };
}

- (CGFloat)x {
    return self.point.x;
}

- (CGFloat)y {
    return self.point.y;
}

@end


@implementation JJZDrawingPath

- (instancetype)init {
    return [self initWithColor:[UIColor blackColor]];
}

- (instancetype)initWithColor:(UIColor *)color {
    return [self initWithPoints:[NSArray new] color:color];
}

- (instancetype)initWithPoints:(NSArray<JJZPoint*> *)points color:(UIColor *)color {
    self = [super init];

    if (self) {
        _color = color;
        _points = [points mutableCopy];
    }

    return self;
}

- (void)addPoint:(CGPoint)point
{
    [self.points addObject:[[JJZPoint alloc] initWithCGPoint:point]];
}

+ (instancetype)drawingPathFromDictionary:(NSDictionary *)dictionary {
    UIColor *color = [UIColor jjz_colorFromHexString:dictionary[kJJZDrawingPathColorKey]];

    NSArray<NSDictionary *> *pointDicts = dictionary[kJJZDrawingPathPointsKey];
    NSMutableArray<JJZPoint *> *points = [NSMutableArray array];

    for (NSDictionary *pointDict in pointDicts) {
        JJZPoint *point = [JJZPoint pointFromDictionary:pointDict];
        if (point != nil) {
            [points addObject:point];
        } else {
            Dlog(@"Invalid point: %@", pointDict);
        }
    }
    return [[JJZDrawingPath alloc] initWithPoints:points color:color];
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    dict[kJJZDrawingPathColorKey] = [self.color jjz_hexString];

    NSMutableArray<NSDictionary *> *pointDicts = [NSMutableArray array];
    for (JJZPoint *point in self.points) {
        [pointDicts addObject:[point dictionaryRepresentation]];
    }
    dict[kJJZDrawingPathPointsKey] = pointDicts;

    return [NSDictionary dictionaryWithDictionary:dict];
}

@end
