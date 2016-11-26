//
//  LMSettingsViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/24/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMSettingsViewController.h"
#import "LMSettingsView.h"
#import "LMSettings.h"
#import "LMCoreViewController.h"

@interface LMSettingsViewController ()

@property LMSettingsView *settingsView;

@end

@implementation LMSettingsViewController

- (BOOL)prefersStatusBarHidden {
	BOOL shouldShowStatusBar = [LMSettings shouldShowStatusBar];
		
	return !shouldShowStatusBar;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
	return UIStatusBarAnimationSlide;
}

- (void)viewDidAppear:(BOOL)animated {
	[(LMCoreViewController*)self.coreViewController setStatusBarBlurHidden:![LMSettings shouldShowStatusBar]];
}

- (void)loadView {
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor cyanColor];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.settingsView = [LMSettingsView newAutoLayoutView];
	self.settingsView.coreViewController = self.coreViewController;
	self.settingsView.settingsViewController = self;
	[self.view addSubview:self.settingsView];
	
	[self.settingsView autoPinEdgesToSuperviewEdges];
	
	NSLog(@"View did load!!!");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
