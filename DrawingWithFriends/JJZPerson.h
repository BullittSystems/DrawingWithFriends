//
//  JJZPerson.h
//  DrawingWithFriends
//
//  Created by Ryan C. Payne on 6/8/16.
//  Copyright © 2016 BullittSystems, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JJZPerson : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *deviceIdentifier;
@property (nonatomic, assign, getter=isOnline) BOOL online;

@property (nonatomic, assign, getter=isAvailable) BOOL available;

@end
