//
//  JJZPeopleManager.h
//  DrawingWithFriends
//
//  Created by Ryan C. Payne on 6/8/16.
//  Copyright © 2016 BullittSystems, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class JJZPeopleManager;
@class JJZPerson;

@protocol JJZPeopleManagerDelegate <NSObject>

@optional
- (void)peopleManager:(JJZPeopleManager *)peopleManager didAddPerson:(JJZPerson *)person;
- (void)peopleManager:(JJZPeopleManager *)peopleManager didUpdatePerson:(JJZPerson *)person;
- (void)peopleManager:(JJZPeopleManager *)peopleManager didRemovePerson:(JJZPerson *)person;

@end

@interface JJZPeopleManager : NSObject

@property (nonatomic, weak) id <JJZPeopleManagerDelegate> delegate;
@property (nonatomic, strong) NSString *myName;
@property (nonatomic, readonly) NSString *myID;
@property (nonatomic, assign, getter=isAvailable) BOOL available;

@property (nonatomic, readonly) NSArray<JJZPerson *> *people;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithMyName:(NSString *)myName delegate:(id <JJZPeopleManagerDelegate>)delegate NS_DESIGNATED_INITIALIZER;

- (JJZPerson *)personForIdentifier:(NSString *)identifier;

@end
