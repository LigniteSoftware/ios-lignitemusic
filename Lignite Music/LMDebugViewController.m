//
//  LMDebugViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/30/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMDebugViewController.h"
#import "LMDebugView.h"
#import "LMAppIcon.h"

@interface LMDebugViewController ()

@property LMDebugView *debugView;

@end

@implementation LMDebugViewController

- (void)loadShit {
	self.debugView = [LMDebugView newAutoLayoutView];
	[self.view addSubview:self.debugView];
	
	[self.debugView autoPinEdgesToSuperviewEdges];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view.
	
	UIImageView *hangOnImage = [UIImageView newAutoLayoutView];
	hangOnImage.image = [LMAppIcon imageForIcon:LMIconNoAlbumArt];
	hangOnImage.contentMode = UIViewContentModeScaleAspectFit;
	[self.view addSubview:hangOnImage];
	
	[hangOnImage autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:self.view.frame.size.width/5.0];
	[hangOnImage autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:self.view.frame.size.width/5.0];
	[hangOnImage autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:self.view.frame.size.height/4.0];
	[hangOnImage autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(1.0/3.0)];
	
	UILabel *hangOnLabel = [UILabel newAutoLayoutView];
	hangOnLabel.text = NSLocalizedString(@"HangOn", nil);
	hangOnLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:30.0f];
	hangOnLabel.textAlignment = NSTextAlignmentCenter;
	[self.view addSubview:hangOnLabel];
	
	[hangOnLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:hangOnImage withOffset:10];
	[hangOnLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[hangOnLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	
	[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(loadShit) userInfo:nil repeats:NO];
	
	NSLog(@"Loaded");
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)loadView {
	NSLog(@"Load view");
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor whiteColor];
}

@end
