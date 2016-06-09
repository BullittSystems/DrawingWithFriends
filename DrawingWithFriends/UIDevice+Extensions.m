//
//  UIDevice+Extensions.m
//  DrawingWithFriends
//
//  Created by Ryan C. Payne on 6/7/16.
//  Copyright © 2016 BullittSystems, Inc. All rights reserved.
//

#import "UIDevice+Extensions.h"

static NSString *const kJJZDeviceUUIDPersistenceKey = @"kJJZDeviceUUIDPersistenceKey";

@implementation UIDevice (Extensions)

- (NSString *)jjz_deviceUUID {
    NSString *uuidString;

#if TARGET_IPHONE_SIMULATOR
    uuidString = [[NSUserDefaults standardUserDefaults] objectForKey:kJJZDeviceUUIDPersistenceKey];

    if (uuidString == nil)
    {
        uuidString = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:uuidString forKey:kJJZDeviceUUIDPersistenceKey];
    }
#else
    uuidString = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
#endif

    return uuidString;
}

@end
