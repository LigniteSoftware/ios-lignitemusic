//
//  LMBrowsingDetailViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/25/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMPebbleSettingsViewController.h"
#import "LMSettings.h"
#import "LMExtras.h"
#import "LMPebbleSettingsView.h"

@interface LMPebbleSettingsViewController ()

@property NSLayoutConstraint *browsingDetailViewHeightConstraint;

@property LMPebbleSettingsView *settingsView;

@end

@implementation LMPebbleSettingsViewController

- (BOOL)prefersStatusBarHidden {
	return ![LMSettings shouldShowStatusBar];
}

- (void)loadView {
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor orangeColor];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view.
	
	self.settingsView = [LMPebbleSettingsView newAutoLayoutView];
	self.settingsView.messageQueue = self.messageQueue;
	[self.view addSubview:self.settingsView];
	
	[self.settingsView autoPinEdgesToSuperviewEdges];
	
	NSLog(@"Did load!");
	
	NSLog(@"shit %@", NSStringFromCGRect(self.view.frame));
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
