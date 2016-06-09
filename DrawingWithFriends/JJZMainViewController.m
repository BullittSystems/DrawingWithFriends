//
//  JJZMainViewController.m
//  DrawingWithFriends
//
//  Created by Ryan C. Payne on 6/8/16.
//  Copyright © 2016 BullittSystems, Inc. All rights reserved.
//

#import "JJZMainViewController.h"
#import "JJZDraggableFloatyView.h"
#import "JJZCanvasView.h"
#import "UIColor+Hex.h"
#import "JJZCredentialManager.h"
#import "JJZPeopleManager.h"
#import "JJZPerson.h"
#import "JJZDrawingManager.h"

#import <TwilioConversationsClient/TwilioConversationsClient.h>

@interface JJZMainViewController () <JJZCanvasViewDelegate, JJZPeopleManagerDelegate, TwilioAccessManagerDelegate, JJZDrawingManagerDelegate>
@property (strong, nonatomic) IBOutlet JJZCanvasView *canvasView;
@property (weak, nonatomic) IBOutlet UIButton *endConversationButton;
@property (weak, nonatomic) IBOutlet UIButton *inviteButton;

@property (strong, nonatomic) TwilioAccessManager *accessManger;

@property (strong, nonatomic) JJZPeopleManager *peopleManager;
@property (strong, nonatomic) JJZDrawingManager *drawingManager;

@end

@implementation JJZMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Initially set it up with the name of the device. We could add the ability to change it later
    self.peopleManager = [[JJZPeopleManager alloc] initWithMyName:[[UIDevice currentDevice] name] delegate:self];

    self.drawingManager = [JJZDrawingManager new];
    self.drawingManager.delegate = self;

    self.canvasView.delegate = self;
    [self changeColor:self];

    // Initial UI State
    self.endConversationButton.enabled = NO;
    self.inviteButton.enabled = NO;

    typeof(self) __weak weakSelf = self;
    [JJZCredentialManager retrieveAccessTokenWithCompletionBlock:^(NSString *accessToken, NSError *error) {
        if (accessToken) {
            typeof(self) __strong strongSelf = weakSelf;
            strongSelf.accessManger = [TwilioAccessManager accessManagerWithToken:accessToken delegate:self];
        } else if (error) {
            NSLog(@"Error retrieving token: %@", error.localizedDescription);
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)changeColor:(id)sender {
    Dlog(@"Change color!");
    self.canvasView.currentColor = [UIColor jjz_randomColor];
}

- (IBAction)clearCanvas:(id)sender {
    [self.drawingManager clearDrawing];
}

- (IBAction)invite:(id)sender {
    if ([self.inviteButton.titleLabel.text isEqualToString:@"Invite"]) {
        [self.inviteButton setTitle:@"Invite Another" forState:UIControlStateNormal];
    } else {
        [self.inviteButton setTitle:@"Invite" forState:UIControlStateNormal];
    }

    [self.inviteButton sizeToFit];
}

- (IBAction)end:(id)sender {
    if ([self.endConversationButton.titleLabel.text isEqualToString:@"End Conversation"]) {
        [self.endConversationButton setTitle:@"Leave Converation" forState:UIControlStateNormal];
    } else {
        [self.endConversationButton setTitle:@"End Converation" forState:UIControlStateNormal];
    }

    [self.endConversationButton sizeToFit];
}

- (void)updateUI {
    // This method will toggle the buttons according to state.
    // If we are part of a Converation and we started it, "End Converation"
    // If we are part of a Converation as a participant, "Leave Converation"

    // If no current converstation:
    // If nobody is online : Invite - Enabled = NO
    // If online and available : Invite - Enabled = YES

    // If part of a conversation:
    // If not the creator : Invite - Enabled = NO
    // If the creator and only one person

    NSUInteger availableCount = 0;

    for (JJZPerson *person in self.peopleManager.availablePeople) {
        if (person.isOnline && person.isAvailable) {
            availableCount++;
        }
    }

    self.inviteButton.enabled = (availableCount > 0);


}

#pragma mark - JJZCanvasViewDelegate
- (void)canvasView:(JJZCanvasView *)canvasView didFinishDrawingPath:(JJZDrawingPath *)drawingPath {
    DFlog(@"Send this path! %@", drawingPath);
    [self.drawingManager persistDrawingPath:drawingPath];
}

#pragma mark - JJZDrawingManagerDelegate
- (void)drawingManager:(JJZDrawingManager *)drawingManager didReceiveDrawingPath:(JJZDrawingPath *)drawingPath {
    [self.canvasView addDrawingPath:drawingPath];
}

- (void)drawingManagerDidClear:(JJZDrawingManager *)drawingManager {
    [self.canvasView clear];
}

#pragma mark - JJZPeopleManagerDelegate
- (void)peopleManager:(JJZPeopleManager *)peopleManager didAddPerson:(JJZPerson *)person {
    DFlog(@"Added person: %@", [person debugDescription]);
    [self updateUI];
}

- (void)peopleManager:(JJZPeopleManager *)peopleManager didUpdatePerson:(JJZPerson *)person {
    DFlog(@"Updated person: %@", [person debugDescription]);
    [self updateUI];
}

- (void)peopleManager:(JJZPeopleManager *)peopleManager didRemovePerson:(JJZPerson *)person {
    DFlog(@"Removed person: %@", [person debugDescription]);
    [self updateUI];
}

#pragma mark - TwilioAccessManagerDelegate
- (void)accessManagerTokenExpired:(TwilioAccessManager *)accessManager {
    DFlog(@"Access Token expired!!!");
}

- (void)accessManager:(TwilioAccessManager *)accessManager error:(NSError *)error {
    DFlog(@"AccessManager Error: %@", error.localizedDescription);
}

@end
