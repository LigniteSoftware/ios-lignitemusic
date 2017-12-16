//
//  LMCoreNavigationController.m
//  Lignite Music
//
//  Created by Edwin Finch on 2017-03-26.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>

#import "LMCoreNavigationController.h"
#import "LMCoreViewController.h"
#import "LMMusicPlayer.h"
#import "LMSettings.h"

@interface LMCoreNavigationController ()<UINavigationControllerDelegate, UINavigationBarDelegate>

@end

@implementation LMCoreNavigationController

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	NSLog(@"View will appear %@", self.interactivePopGestureRecognizer.delegate);

//	self.delegate = self;
//	self.navigationBar.delegate = self;
	
	
	
	UIViewController *fromViewController = [[[self navigationController] transitionCoordinator] viewControllerForKey:UITransitionContextFromViewControllerKey];

	if (![[self.navigationController viewControllers] containsObject:fromViewController]){
		for(UIViewController *viewController in self.viewControllers){
			NSLog(@"View controller %@", [viewController.class description]);
			NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
			if(viewController.class == [LMCoreViewController class] && [userDefaults objectForKey:LMSettingsKeyOnboardingComplete]){
				LMCoreViewController *coreViewController = (LMCoreViewController*)viewController;
				[coreViewController prepareToLoadView];
			}
		}
	}

}

//- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
//	[super encodeRestorableStateWithCoder:coder];
//}
//
//- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
//	[super decodeRestorableStateWithCoder:coder];
//}

//- (instancetype)initWithCoder:(NSCoder *)aDecoder {
//	self = [super initWithCoder:aDecoder];
//	
//	if(self){
//		self.rootView = [LMView newAutoLayoutView];
//		self.rootView.userInteractionEnabled = YES;
//		self.rootView.backgroundColor = [UIColor magentaColor];
//		[self.view addSubview:self.rootView];
//		
//		[self.rootView autoPinEdgesToSuperviewEdges];
//	}
//	
//	return self;
//}

@end
