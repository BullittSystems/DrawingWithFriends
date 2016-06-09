//
//  JJZConversaationManager.m
//  DrawingWithFriends
//
//  Created by Ryan C. Payne on 6/9/16.
//  Copyright © 2016 BullittSystems, Inc. All rights reserved.
//

#import "JJZConversationManager.h"
#import "UIDevice+Extensions.h"

#import <TwilioConversationsClient/TwilioConversationsClient.h>

static NSString *const kTokenGenerationEndpoint = @"https://salty-eyrie-76190.herokuapp.com/token?device_id=";

@interface JJZConversationManager() <TwilioAccessManagerDelegate>

@property (nonatomic, strong) TwilioAccessManager *accessManger;

@end

@implementation JJZConversationManager

- (instancetype)init {
    self = [super init];

    if (self) {
        [self fetchAccessToken];
    }

    return self;
}

- (void)fetchAccessToken {
    NSString *deviceIdentifier = [[UIDevice currentDevice] jjz_deviceUUID];
    NSString *urlString = [kTokenGenerationEndpoint stringByAppendingString:deviceIdentifier];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];

    typeof(self) __weak weakSelf = self;
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        typeof(self) __strong strongSelf = weakSelf;
        if (data && strongSelf) {

            NSString *accessToken = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

            if (strongSelf.accessManger) {
                [strongSelf.accessManger updateToken:accessToken];
            } else {
                strongSelf.accessManger = [TwilioAccessManager accessManagerWithToken:accessToken delegate:self];
            }
        }
    }] resume];
}

#pragma mark - TwilioAccessManagerDelegate
- (void)accessManagerTokenExpired:(TwilioAccessManager *)accessManager {
    DFlog(@"Access Token expired!!!");
}

- (void)accessManager:(TwilioAccessManager *)accessManager error:(NSError *)error {
    DFlog(@"AccessManager Error: %@", error.localizedDescription);
}

@end
