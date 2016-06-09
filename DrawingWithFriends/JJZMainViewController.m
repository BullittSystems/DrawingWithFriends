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

#import <TwilioConversationsClient/TwilioConversationsClient.h>

@interface JJZMainViewController () <JJZCanvasViewDelegate, TwilioAccessManagerDelegate>
@property (strong, nonatomic) IBOutlet JJZCanvasView *canvasView;

@property (strong, nonatomic) TwilioAccessManager *accessManger;

@end

@implementation JJZMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.canvasView.delegate = self;

    [self changeColor:self];

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
    [self.canvasView clear];
}

#pragma mark - JJZCanvasViewDelegate
- (void)canvasView:(JJZCanvasView *)canvasView didFinishDrawingPath:(JJZDrawingPath *)drawingPath {

}

- (void)didClearCanvasView:(JJZCanvasView *)canvasView {

}

#pragma mark - TwilioAccessManagerDelegate
- (void)accessManagerTokenExpired:(TwilioAccessManager *)accessManager {
    DFlog(@"Access Token expired!!!");
}

- (void)accessManager:(TwilioAccessManager *)accessManager error:(NSError *)error {
    DFlog(@"AccessManager Error: %@", error.localizedDescription);
}

@end
