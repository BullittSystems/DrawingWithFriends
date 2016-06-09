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

@interface JJZMainViewController () <JJZCanvasViewDelegate>
@property (strong, nonatomic) IBOutlet JJZCanvasView *canvasView;

@end

@implementation JJZMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.canvasView.delegate = self;

    [self changeColor:self];
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

@end
