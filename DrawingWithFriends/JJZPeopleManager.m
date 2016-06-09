//
//  JJZPeopleManager.m
//  DrawingWithFriends
//
//  Created by Ryan C. Payne on 6/8/16.
//  Copyright © 2016 BullittSystems, Inc. All rights reserved.
//

#import "JJZPeopleManager.h"
#import <Firebase/Firebase.h>
#import "UIDevice+Extensions.h"
#import "JJZPerson.h"

#pragma mark - Constants
static NSString *const kFirebaseRootURL = @"https://drawingwithfriends.firebaseio.com";
static NSString *const kPeopleKey = @"people";
static NSString *const kPersonNameKey = @"name";
static NSString *const kPersonIsOnlineKey = @"is_online";
static NSString *const kPersonIsAvailableKey = @"is_available";

@interface JJZPeopleManager()

@property (nonatomic, strong) NSMutableDictionary<NSString *, JJZPerson *> *people;
@property (nonatomic, strong) JJZPerson *me;

// Firebase references
@property (nonatomic, strong) Firebase *rootRef;
@property (nonatomic, strong) Firebase *peopleRef;
@property (nonatomic, strong) Firebase *myPersonRef;

@property (nonatomic, strong) NSMutableDictionary *firebaseObservers;

@end

@implementation JJZPeopleManager

// Even though we marked this initializer as NS_UNAVAILABLE, we want it to fail fast during development
// if somebody accidentally does `[<Class> new]`.
- (instancetype)init
{
    self = nil;

    NSException *exception = [NSException exceptionWithName:@"JJZPeopleManagerInitializationException" reason:@"JJZPeopleManager requires the use of the parameterized initializer." userInfo:nil];
    [exception raise];

    return self;
}

- (instancetype)initWithMyName:(NSString *)myName delegate:(id <JJZPeopleManagerDelegate>)delegate {
    self = [super init];

    if (self) {
        _me = [JJZPerson new];
        _me.name = myName;
        _me.deviceIdentifier = [[UIDevice currentDevice] jjz_deviceUUID];
        _me.online = YES;

        _people = [NSMutableDictionary new];
        _rootRef = [[Firebase alloc] initWithUrl:kFirebaseRootURL];
        _peopleRef = [_rootRef childByAppendingPath:kPeopleKey];
        _myPersonRef = [_peopleRef childByAppendingPath:_me.deviceIdentifier];

        [self.myPersonRef updateChildValues:@{ kPersonNameKey : _me.name,
                                               kPersonIsOnlineKey : @(YES),
                                               kPersonIsAvailableKey : @(YES) }];

        [self registerForLocalChangeNotifications];
        [self registerForRemoteChangeNotifications];
        [self registerOnDisconnectHandler];
    }

    return self;
}

- (void)dealloc {
    [self removeOnDisconnectHandler];
    [self unregisterForLocalChangeNotifications];
    [self unregisterFromRemoteChangeNotifications];

    [self.myPersonRef removeValue];
}

- (void)setMyName:(NSString *)myName {
    [self updateMyName:myName];
}

- (NSString *)myName {
    return self.me.name;
}

- (void)setAvailable:(BOOL)available {
    [self updateAvailability:available];
}

- (BOOL)isAvailable {
    return self.me.isAvailable;
}

#pragma mark - People Collection Methods
- (void)addPerson:(JJZPerson *)person {
    self.people[person.deviceIdentifier] = person;

    if ([self.delegate respondsToSelector:@selector(peopleManager:didAddPerson:)]) {
        [self.delegate peopleManager:self didAddPerson:person];
    }
}

- (void)updatePerson:(JJZPerson *)person {
    self.people[person.deviceIdentifier] = person;

    if ([self.delegate respondsToSelector:@selector(peopleManager:didUpdatePerson:)]) {
        [self.delegate peopleManager:self didUpdatePerson:person];
    }
}

- (void)removePersonByKey:(NSString *)key {
    JJZPerson *person = self.people[key];

    if (person) {
        self.people[key] = nil;

        if ([self.delegate respondsToSelector:@selector(peopleManager:didRemovePerson:)]) {
            [self.delegate peopleManager:self didRemovePerson:person];
        }
    }
}

- (JJZPerson *)personFromSnapshot:(FDataSnapshot *)snapshot {
    JJZPerson *person = nil;

    if ([snapshot.value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *personDict = (NSDictionary *)snapshot.value;

        person = [JJZPerson new];
        person.name = personDict[kPersonNameKey];
        person.deviceIdentifier = snapshot.key;
        person.online = [personDict[kPersonIsOnlineKey] boolValue];
        person.available = [personDict[kPersonIsAvailableKey] boolValue];
    }

    return person;
}

- (NSArray *)availablePeople {
    return [self.people allValues];
}

- (JJZPerson *)personForIdentifier:(NSString *)identifier {
    return self.people[identifier];
}

#pragma mark - Local Change Notification Handlers
- (void)registerForLocalChangeNotifications {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    [nc addObserver:self selector:@selector(handleResignActiveEvent:) name:UIApplicationWillResignActiveNotification object:[UIApplication sharedApplication]];
    [nc addObserver:self selector:@selector(handleBecomeActiveEvent:) name:UIApplicationDidBecomeActiveNotification object:[UIApplication sharedApplication]];
}

- (void)unregisterForLocalChangeNotifications {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    [nc removeObserver:self name:UIApplicationWillResignActiveNotification object:[UIApplication sharedApplication]];
    [nc removeObserver:self name:UIApplicationDidBecomeActiveNotification object:[UIApplication sharedApplication]];
}

- (void)handleResignActiveEvent:(NSNotification *)note {
    [self updateIsOnline:NO];
}

- (void)handleBecomeActiveEvent:(NSNotification *)note {
    [self updateIsOnline:YES];
}

#pragma mark - Firebase accessors
- (void)updateMyName:(NSString *)myName {
    self.me.name = myName;
    [self.myPersonRef updateChildValues:@{ kPersonNameKey : self.me.name }];
}

- (void)updateIsOnline:(BOOL)isOnline {
    self.me.online = isOnline;
    [self.myPersonRef updateChildValues:@{ kPersonIsOnlineKey : @(isOnline) }];
}

- (void)updateAvailability:(BOOL)isAvailable {
    self.me.available = isAvailable;
    [self.myPersonRef updateChildValues:@{ kPersonIsAvailableKey : @(isAvailable) }];
}

#pragma mark - Remote Change Notification Handlers
- (void)registerObserverOnFirebase:(Firebase *)firebase observeEventType:(FEventType)eventType withBlock:(void (^)(FDataSnapshot *snapshot))block
{
    if (firebase == nil) {
        return;
    }
    FirebaseHandle handle = [firebase observeEventType:eventType withBlock:block];
    self.firebaseObservers[@(handle)] = firebase;
}

- (void)registerForRemoteChangeNotifications {
    typeof(self) __weak weakSelf = self;

    [self registerObserverOnFirebase:self.peopleRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        typeof(self) __strong strongSelf = weakSelf;
        [strongSelf onNewRemotePersonHandler:snapshot];
    }];

    [self registerObserverOnFirebase:self.peopleRef observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        typeof(self) __strong strongSelf = weakSelf;
        [strongSelf onRemotePersonChangedHandler:snapshot];
    }];

    [self registerObserverOnFirebase:self.peopleRef observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        typeof(self) __strong strongSelf = weakSelf;
        [strongSelf onRemotePersonRemovedHandler:snapshot];
    }];
}

- (void)unregisterFromRemoteChangeNotifications
{
    [self.firebaseObservers enumerateKeysAndObjectsUsingBlock:^(NSNumber *handle, Firebase *firebase, BOOL *stop) {
        [firebase removeObserverWithHandle:[handle unsignedIntegerValue]];
    }];

    [self.firebaseObservers removeAllObjects];
}

- (void)onNewRemotePersonHandler:(FDataSnapshot *)snapshot {
    if (![snapshot.key isEqualToString:self.me.deviceIdentifier]) {
        [self addPerson:[self personFromSnapshot:snapshot]];
    }
}

- (void)onRemotePersonChangedHandler:(FDataSnapshot *)snapshot {
    if (![snapshot.key isEqualToString:self.me.deviceIdentifier]) {
        [self updatePerson:[self personFromSnapshot:snapshot]];
    }
}

- (void)onRemotePersonRemovedHandler:(FDataSnapshot *)snapshot {
    if (![snapshot.key isEqualToString:self.me.deviceIdentifier]) {
        [self removePersonByKey:snapshot.key];
    }
}

#pragma mark - Ungraceful Disconnect Handler

- (void)registerOnDisconnectHandler
{
    [self.myPersonRef onDisconnectUpdateChildValues:@{ kPersonIsOnlineKey : @(NO) }];
}

- (void)removeOnDisconnectHandler
{
    [self.myPersonRef cancelDisconnectOperations];
}

@end


