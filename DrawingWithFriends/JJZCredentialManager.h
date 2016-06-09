//
//  JJZCredentialManager.h
//  DrawingWithFriends
//
//  Created by Ryan C. Payne on 6/8/16.
//  Copyright © 2016 BullittSystems, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JJZCredentialManager : NSObject

+ (void)retrieveAccessTokenWithCompletionBlock:(void(^)(NSString *accessToken, NSError *error))completionBlock;

@end
