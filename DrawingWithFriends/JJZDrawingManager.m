//
//  JJZDrawingManager.m
//  DrawingWithFriends
//
//  Created by Ryan C. Payne on 6/9/16.
//  Copyright © 2016 BullittSystems, Inc. All rights reserved.
//

#import "JJZDrawingManager.h"
#import <Firebase/Firebase.h>
#import "UIDevice+Extensions.h"
#import "JJZDrawingPath.h"

#pragma mark - Constants
static NSString *const kFirebaseRootURL = @"https://drawingwithfriends.firebaseio.com";
static NSString *const kDrawingKey = @"drawing";

@interface JJZDrawingManager()

@property (nonatomic, strong) NSMutableArray<JJZDrawingPath *> *paths;
@property (nonatomic, strong) NSMutableSet<NSString *> *myPathIDs;

// Firebase references
@property (nonatomic, strong) Firebase *rootRef;
@property (nonatomic, strong) Firebase *drawingRef;
@property (nonatomic, strong) Firebase *myPersonRef;

@property (nonatomic, strong) NSMutableDictionary *firebaseObservers;

@end

@implementation JJZDrawingManager

- (instancetype)init {
    self = [super init];

    if (self) {
        _paths = [NSMutableArray new];
        _myPathIDs = [NSMutableSet new];

        _rootRef = [[Firebase alloc] initWithUrl:kFirebaseRootURL];
        _drawingRef = [_rootRef childByAppendingPath:kDrawingKey];

        [self registerForRemoteChangeNotifications];
    }

    return self;
}

- (void)dealloc {
    [self unregisterFromRemoteChangeNotifications];
}

- (NSArray<JJZDrawingPath *> *)drawingPaths {
    return [NSArray arrayWithArray:self.paths];
}

- (void)clearDrawing {
    [self.drawingRef removeValue];
}

- (void)persistDrawingPath:(JJZDrawingPath *)drawingPath {
    Firebase *pathRef = [self.drawingRef childByAutoId];

    NSString *pathID = pathRef.key;
    [self.myPathIDs addObject:pathID];

    [pathRef setValue:[drawingPath dictionaryRepresentation] withCompletionBlock:^(NSError *error, Firebase *ref) {
        [self.myPathIDs removeObject:pathID];
    }];
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

    [self registerObserverOnFirebase:self.drawingRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        typeof(self) __strong strongSelf = weakSelf;
        [strongSelf onNewDrawingPathHandler:snapshot];
    }];

    [self registerObserverOnFirebase:self.rootRef observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        typeof(self) __strong strongSelf = weakSelf;
        if ([snapshot.key isEqualToString:kDrawingKey]) {
            [strongSelf onDrawingClearedHandler:snapshot];
        }
    }];
}

- (void)unregisterFromRemoteChangeNotifications
{
    [self.firebaseObservers enumerateKeysAndObjectsUsingBlock:^(NSNumber *handle, Firebase *firebase, BOOL *stop) {
        [firebase removeObserverWithHandle:[handle unsignedIntegerValue]];
    }];

    [self.firebaseObservers removeAllObjects];
}

- (void)onNewDrawingPathHandler:(FDataSnapshot *)snapshot {
    if (![self.myPathIDs containsObject:snapshot.key]) {
        JJZDrawingPath *drawingPath = [JJZDrawingPath drawingPathFromDictionary:snapshot.value];

        if (drawingPath) {
            [self.delegate drawingManager:self didReceiveDrawingPath:drawingPath];
        } else {
            DFlog(@"Invalid drawing data received!");
        }
    } else {
        // We were the ones that created this path.
    }
}

- (void)onDrawingClearedHandler:(FDataSnapshot *)snapshot {
    self.paths = [NSMutableArray new];
    self.myPathIDs = [NSMutableSet new];

    [self.delegate drawingManagerDidClear:self];
}

@end
