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
#import "UIDevice+Extensions.h"

#import <TwilioConversationsClient/TwilioConversationsClient.h>

@interface JJZMainViewController () <JJZCanvasViewDelegate, JJZPeopleManagerDelegate, JJZDrawingManagerDelegate, UIAlertViewDelegate,
                                     TwilioAccessManagerDelegate, TwilioConversationsClientDelegate, TWCConversationDelegate,
                                     TWCLocalMediaDelegate, TWCVideoTrackDelegate, TWCParticipantDelegate>

@property (strong, nonatomic) IBOutlet JJZCanvasView *canvasView;
@property (weak, nonatomic) IBOutlet UIButton *endConversationButton;
@property (weak, nonatomic) IBOutlet UIButton *inviteButton;

@property (weak, nonatomic) UIAlertView *incomingAlert;

@property (strong, nonatomic) TwilioAccessManager *accessManager;
@property (nonatomic, strong) TwilioConversationsClient *conversationsClient;

@property (nonatomic, strong) TWCLocalMedia *localMedia;
@property (nonatomic, strong) TWCCameraCapturer *camera;
@property (nonatomic, strong) TWCConversation *conversation;
@property (nonatomic, strong) TWCOutgoingInvite *outgoingInvite;
@property (nonatomic, strong) TWCIncomingInvite *incomingInvite;

// Allow up to two people other people
@property (nonatomic, weak) TWCParticipant *participant1;
@property (nonatomic, weak) TWCParticipant *participant2;

@property (nonatomic, strong) JJZDraggableFloatyView *localVideoView;
@property (nonatomic, strong) JJZDraggableFloatyView *participant1VideoView;
@property (nonatomic, strong) JJZDraggableFloatyView *participant2VideoView;

@property (strong, nonatomic) JJZPeopleManager *peopleManager;
@property (strong, nonatomic) JJZDrawingManager *drawingManager;

@end

@implementation JJZMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [TwilioConversationsClient setAudioOutput:TWCAudioOutputDefault];

    // Initially set it up with the name of the device. We could add the ability to change it later
    self.peopleManager = [[JJZPeopleManager alloc] initWithMyName:[[UIDevice currentDevice] name] delegate:self];

    self.drawingManager = [JJZDrawingManager new];
    self.drawingManager.delegate = self;

    self.canvasView.delegate = self;
    [self changeColor:self];

    // Initial UI State
    self.endConversationButton.enabled = NO;
    self.inviteButton.enabled = NO;

    // Prepare our floaty views
    self.localVideoView = [[JJZDraggableFloatyView alloc] initWithFrame:CGRectMake(20, 20, 120, 160)];
    self.participant1VideoView = [[JJZDraggableFloatyView alloc] initWithFrame:CGRectMake(20, 200, 120, 160)];
    self.participant2VideoView = [[JJZDraggableFloatyView alloc] initWithFrame:CGRectMake(20, 380, 120, 160)];

    // Finally, start listening for invites from others
    [self listenForInvites];
}

- (void)listenForInvites {
    [TwilioConversationsClient setLogLevel:TWCLogLevelWarning];

    typeof(self) __weak weakSelf = self;
    [JJZCredentialManager retrieveAccessTokenWithCompletionBlock:^(NSString *accessToken, NSError *error) {
        if (accessToken) {
            typeof(self) __strong strongSelf = weakSelf;

            if (!strongSelf.accessManager) {
                strongSelf.accessManager = [TwilioAccessManager accessManagerWithToken:accessToken delegate:self];
            } else {
                [strongSelf.accessManager updateToken:accessToken];
            }

            strongSelf.conversationsClient = [TwilioConversationsClient conversationsClientWithAccessManager:strongSelf.accessManager delegate:self];
            [strongSelf.conversationsClient listen];
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
    self.inviteButton.enabled = NO;
    self.endConversationButton.enabled = YES;
    self.peopleManager.available = NO;
    [self invitePeople];
}

- (IBAction)end:(id)sender {
    [self resetConversation];
    [self updateInviteUI];
}

- (void)resetConversation {
    [self.conversation disconnect];
    self.conversation = nil;

    [self.outgoingInvite cancel];
    self.outgoingInvite = nil;

    [self.incomingInvite reject];
    self.incomingInvite = nil;

    self.localMedia = nil;
    self.camera = nil;

    self.peopleManager.available = YES;

    self.endConversationButton.enabled = NO;
    [self updateInviteUI];

    [self.localVideoView removeFromSuperview];
    [self.participant1VideoView removeFromSuperview];
    [self.participant2VideoView removeFromSuperview];
}

// Setup local media
- (void)prepareLocalMedia {
    self.localMedia = [[TWCLocalMedia alloc] initWithDelegate:self];

#if !TARGET_IPHONE_SIMULATOR
    self.camera = [self.localMedia addCameraTrack];
#else
#endif

    if (self.camera) {
        [self.camera.videoTrack attach:self.localVideoView];
        self.camera.videoTrack.delegate = self;
    }
}

// RCP: Presently this is very brute force... Find the first two available people and invite them...
- (void)invitePeople {
    NSMutableArray<NSString *> *peopleIDs = [NSMutableArray new];

    for (JJZPerson *person in self.peopleManager.people) {
        if (person.isOnline && person.isAvailable) {
            [peopleIDs addObject:person.deviceIdentifier];
        }

        // Only allow up to two other people at the present...
        if ([peopleIDs count] == 2) {
            break;
        }
    }

    [self prepareLocalMedia];

    /*
     RCP: So I am seeing a really odd thing with this... I can reproduce this when starting the
     conversation from my iPad simulator and two actual devices. When the invites are received
     on the iPads, the one has the identifer of the iPad simulator as the inviter.. And the other one
     ends up getting the identifier of the first iPad.
     
     When the conversation is started from one of the iPads, both the simulator and other iPad see the 
     inviter as the first iPad.
     
     OK. I take that back. Its reproduction is unreliable. It seems to have somethign to do with creating
     susequent conversations.
     */
    self.outgoingInvite = [self.conversationsClient inviteManyToConversation:peopleIDs
                                                                  localMedia:self.localMedia
                                                                     handler:[self acceptHandler]];
}

- (void)joinConversationFromInvite:(TWCIncomingInvite *)invite {
    [self prepareLocalMedia];
    [invite acceptWithLocalMedia:self.localMedia
                      completion:[self acceptHandler]];

    self.peopleManager.available = NO;
    self.endConversationButton.enabled = YES;
    [self updateInviteUI];
}

- (TWCInviteAcceptanceBlock)acceptHandler
{
    return ^(TWCConversation * _Nullable conversation, NSError * _Nullable error) {
        if (conversation) {
            conversation.delegate = self;
            self.conversation = conversation;

            if (self.localVideoView) {
                [self.view addSubview:self.localVideoView];
            }
        }
        else {
            DFlog(@"Invite failed with error: %@", error);
        }
    };
}

- (void)updateInviteUI {
    if (self.peopleManager.isAvailable) {
        NSUInteger availableCount = 0;

        for (JJZPerson *person in self.peopleManager.people) {
            if (person.isOnline && person.isAvailable) {
                availableCount++;
            }
        }

        self.inviteButton.enabled = (availableCount > 0);
    } else {
        self.inviteButton.enabled = NO;
    }
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
    [self updateInviteUI];
}

- (void)peopleManager:(JJZPeopleManager *)peopleManager didUpdatePerson:(JJZPerson *)person {
    DFlog(@"Updated person: %@", [person debugDescription]);
    [self updateInviteUI];
}

- (void)peopleManager:(JJZPeopleManager *)peopleManager didRemovePerson:(JJZPerson *)person {
    DFlog(@"Removed person: %@", [person debugDescription]);
    [self updateInviteUI];
}

#pragma mark - TwilioAccessManagerDelegate
- (void)accessManagerTokenExpired:(TwilioAccessManager *)accessManager {
    DFlog(@"Access Token expired!!!");
}

- (void)accessManager:(TwilioAccessManager *)accessManager error:(NSError *)error {
    DFlog(@"AccessManager Error: %@", error.localizedDescription);
}

#pragma mark - TwilioConversationsClientDelegate
- (void)conversationsClientDidStartListeningForInvites:(nonnull TwilioConversationsClient *)conversationsClient {
    DFlog(@"Did start listening for invites");
}

- (void)conversationsClient:(nonnull TwilioConversationsClient *)conversationsClient didFailToStartListeningWithError:(nonnull NSError *)error {
    DFlog(@"Failed to start listening for invites: %@", error.localizedDescription);
}

- (void)conversationsClientDidStopListeningForInvites:(nonnull TwilioConversationsClient *)conversationsClient error:(nullable NSError *)error {
    DFlog(@"Did stop listening for invites: %@", error.localizedDescription);
}

- (void)conversationsClient:(nonnull TwilioConversationsClient *)conversationsClient didReceiveInvite:(nonnull TWCIncomingInvite *)invite {
    DFlog(@"Received invite: %@", invite);

    if (self.conversation || self.incomingInvite) {
        [invite reject];
        return;
    }

    self.incomingInvite = invite;

    NSString *incomingFrom = [NSString stringWithFormat:@"%@ would like to chat.", [self.peopleManager personForIdentifier:invite.from].name];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:incomingFrom
                                                       delegate:self
                                              cancelButtonTitle:@"Reject"
                                              otherButtonTitles:@"Accept", nil];
    [alertView show];
    self.incomingAlert = alertView;
}

- (void)conversationsClient:(nonnull TwilioConversationsClient *)conversationsClient inviteDidCancel:(nonnull TWCIncomingInvite *)invite {
    DFlog(@"Invite was cancelled: %@", invite);

    [self.incomingAlert dismissWithClickedButtonIndex:0 animated:YES];
    self.incomingInvite = nil;
}

#pragma mark - TWCConversationDelegate
- (void)conversation:(nonnull TWCConversation *)conversation didConnectParticipant:(nonnull TWCParticipant *)participant {
    DFlog(@"conversation:didConnectParticipant:");

    if (!self.participant1) {
        self.participant1 = participant;
        [self.view addSubview:self.participant1VideoView];
    } else {
        self.participant2 = participant;
        [self.view addSubview:self.participant2VideoView];
    }

    participant.delegate = self;
}

- (void)conversation:(nonnull TWCConversation *)conversation didFailToConnectParticipant:(nonnull TWCParticipant *)participant error:(nonnull NSError *)error {
    DFlog(@"conversation:didFailToConnectParticipant:");
}

- (void)conversation:(nonnull TWCConversation *)conversation didDisconnectParticipant:(nonnull TWCParticipant *)participant {
    DFlog(@"conversation:didDisconnectParticipant:");
    if ([participant.identity isEqualToString:self.participant1.identity]) {
        [self.participant1VideoView removeFromSuperview];
    } else {
        [self.participant2VideoView removeFromSuperview];
    }
}

- (void)conversationEnded:(nonnull TWCConversation *)conversation {
    DFlog(@"conversationEnded:");
    [self resetConversation];
}

- (void)conversationEnded:(nonnull TWCConversation *)conversation error:(nonnull NSError *)error {
    DFlog(@"conversationEnded:error:");
    [self resetConversation];
}

#pragma mark - TWCLocalMediaDelegate
- (void)localMedia:(nonnull TWCLocalMedia *)media didAddVideoTrack:(nonnull TWCVideoTrack *)videoTrack {
    DFlog(@"localMedia:didAddVideoTrack:");
}

- (void)localMedia:(nonnull TWCLocalMedia *)media didFailToAddVideoTrack:(nonnull TWCVideoTrack *)videoTrack error:(nonnull NSError *)error {
    DFlog(@"localMedia:didFailToAddVideoTrack:error:");
}

- (void)localMedia:(nonnull TWCLocalMedia *)media didRemoveVideoTrack:(nonnull TWCVideoTrack *)videoTrack {
    DFlog(@"localMedia:didRemoveVideoTrack:");
}

#pragma mark - TWCVideoTrackDelegate
- (void)videoTrack:(nonnull TWCVideoTrack *)track dimensionsDidChange:(CMVideoDimensions)dimensions {
    DFlog(@"videoTrack:dimensionsDidChange:");
}

#pragma mark - TWCParticipantDelegate
- (void)participant:(nonnull TWCParticipant *)participant addedVideoTrack:(nonnull TWCVideoTrack *)videoTrack {
    DFlog(@"participant:addedVideoTrack:");

    if ([participant.identity isEqualToString:self.participant1.identity]) {
        [videoTrack attach:self.participant1VideoView];
    } else {
        [videoTrack attach:self.participant2VideoView];
    }

    videoTrack.delegate = self;
}

- (void)participant:(nonnull TWCParticipant *)participant removedVideoTrack:(nonnull TWCVideoTrack *)videoTrack {
    DFlog(@"participant:removedVideoTrack:");
}

- (void)participant:(nonnull TWCParticipant *)participant addedAudioTrack:(nonnull TWCAudioTrack *)audioTrack {
    DFlog(@"participant:addedAudioTrack:");
}

- (void)participant:(nonnull TWCParticipant *)participant removedAudioTrack:(nonnull TWCAudioTrack *)audioTrack {
    DFlog(@"participant:removedAudioTrack:");
}

- (void)participant:(nonnull TWCParticipant *)participant disabledTrack:(nonnull TWCMediaTrack *)track {
    DFlog(@"participant:disabledTrack:");
}

- (void)participant:(nonnull TWCParticipant *)participant enabledTrack:(nonnull TWCMediaTrack *)track {
    DFlog(@"participant:enabledTrack:");
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self.incomingInvite reject];
    } else {
        [self joinConversationFromInvite:self.incomingInvite];
    }

    self.incomingInvite = nil;
}

@end
