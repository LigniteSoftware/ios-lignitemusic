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
#import "LMLayoutManager.h"

@interface LMPebbleSettingsViewController ()<UIViewControllerRestoration>

@property NSLayoutConstraint *browsingDetailViewHeightConstraint;

@property LMPebbleSettingsView *settingsView;

@end

@implementation LMPebbleSettingsViewController

- (instancetype)init {
	self = [super init];
	if(self) {
		self.restorationIdentifier = [[LMPebbleSettingsViewController class] description];
		self.restorationClass = [LMPebbleSettingsViewController class];
	}
	return self;
}

+ (UIViewController*)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
	return [LMPebbleSettingsViewController new];
}

- (BOOL)prefersStatusBarHidden {
	return ![LMSettings shouldShowStatusBar] || [LMLayoutManager sharedLayoutManager].isLandscape;
}

- (void)loadView {
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor clearColor];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view.
	
	self.settingsView = [LMPebbleSettingsView newAutoLayoutView];
	self.settingsView.messageQueue = self.messageQueue;
	self.settingsView.coreViewController = self;
	[self.view addSubview:self.settingsView];
	
	NSArray *settingsViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.settingsView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.settingsView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.settingsView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.settingsView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:44];
	}];
	[LMLayoutManager addNewPortraitConstraints:settingsViewPortraitConstraints];
	
	NSArray *settingsViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.settingsView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:64];
		[self.settingsView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.settingsView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.settingsView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	}];
	[LMLayoutManager addNewLandscapeConstraints:settingsViewLandscapeConstraints];
}

- (void)dealloc {
	[LMLayoutManager removeAllConstraintsRelatedToView:self.settingsView];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
