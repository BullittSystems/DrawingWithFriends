//
//  JJZConversationManager.h
//  DrawingWithFriends
//
//  Created by Ryan C. Payne on 6/9/16.
//  Copyright © 2016 BullittSystems, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class JJZConversationManager;

@protocol JJZConversationManagerDelegate <NSObject>

@end

@interface JJZConversationManager : NSObject

@property (nonatomic, weak) id <JJZConversationManagerDelegate> delegate;

@end
