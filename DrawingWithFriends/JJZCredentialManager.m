//
//  JJZCredentialManager.m
//  DrawingWithFriends
//
//  Created by Ryan C. Payne on 6/8/16.
//  Copyright © 2016 BullittSystems, Inc. All rights reserved.
//

#import "JJZCredentialManager.h"
#import "UIDevice+Extensions.h"

static NSString *const kTokenGenerationEndpoint = @"https://salty-eyrie-76190.herokuapp.com/token?device_id=";

@implementation JJZCredentialManager

+ (void)retrieveAccessTokenWithCompletionBlock:(void(^)(NSString *accessToken, NSError *error))completionBlock {
    if (!completionBlock) {
        return;
    }

    NSString *deviceIdentifier = [[UIDevice currentDevice] jjz_deviceUUID];
    NSString *urlString = [kTokenGenerationEndpoint stringByAppendingString:deviceIdentifier];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];

    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSString *accessToken;

        if (data) {
            accessToken = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }

        completionBlock(accessToken, error);
    }] resume];
}

@end
