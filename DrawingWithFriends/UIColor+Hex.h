//
//  UIColor+Hex.h
//  DrawingWithFriends
//
//  Created by Ryan C. Payne on 6/8/16.
//  Copyright © 2016 BullittSystems, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Hex)

+ (UIColor *)jjz_colorFromHexString:(NSString *)hexString;
- (NSString *)jjz_hexString;

@end
