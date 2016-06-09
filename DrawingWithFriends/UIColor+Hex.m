//
//  UIColor+Hex.m
//  DrawingWithFriends
//
//  Created by Ryan C. Payne on 6/8/16.
//  Copyright © 2016 BullittSystems, Inc. All rights reserved.
//

#import "UIColor+Hex.h"

@implementation UIColor (Hex)

+ (UIColor *)jjz_colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;

    if (hexString) {
        NSScanner *scanner = [NSScanner scannerWithString:hexString];

        if ([hexString hasPrefix:@"#"]) {
            [scanner setScanLocation:1];
        }

        [scanner scanHexInt:&rgbValue];
    }

    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16) / 255.0
                           green:((rgbValue & 0xFF00) >> 8) / 255.0
                            blue:(rgbValue & 0xFF) / 255.0
                           alpha:1.0];
}

- (NSString *)jjz_hexString {
    NSString *hexString = @"#ffffff";

    // Special case, as white doesn't fall into the RGB color space
    if (self != [UIColor whiteColor]) {
        CGFloat red;
        CGFloat blue;
        CGFloat green;
        CGFloat alpha;

        [self getRed:&red green:&green blue:&blue alpha:&alpha];

        int redDec = (int)(red * 255);
        int greenDec = (int)(green * 255);
        int blueDec = (int)(blue * 255);

        hexString = [NSString stringWithFormat:@"#%02x%02x%02x", (unsigned int)redDec, (unsigned int)greenDec, (unsigned int)blueDec];
    }
    
    return hexString;
}

+ (NSString *)jjz_randomHexString {
    unsigned int red = floor(arc4random() % 255);
    unsigned int green = floor(arc4random() % 255);
    unsigned int blue = floor(arc4random() % 255);

    return [NSString stringWithFormat:@"#%02x%02x%02x", red, green, blue];
}

+ (UIColor *)jjz_randomColor {
    return [UIColor jjz_colorFromHexString:[UIColor jjz_randomHexString]];
}

@end
