//
//  LMGuideViewPagerController.h
//  Lignite
//
//  Created by Edwin Finch in 2016.
//  Copyright © 2016 Edwin Finch. All rights reserved.
//

#import <PureLayout/PureLayout.h>

#import "LMGuideViewPagerController.h"
#import "LMGuideViewController.h"
#import "LMLayoutManager.h"
#import "LMColour.h"

#define LMOnboardingViewControllerIndexKey @"LMOnboardingViewControllerIndexKey"

@interface LMGuideViewPagerController () <LMLayoutChangeDelegate, UIViewControllerRestoration>

@property NSArray *titleArray, *descriptionArray, *screenshotsArray, *buttonNamesArray;

@property NSInteger amountOfPages;

@property UIImageView *backgroundImageView;

@property LMLayoutManager *layoutManager;

@end

@implementation LMGuideViewPagerController

- (instancetype)init {
	self = [super init];
	if(self) {
//		self.restorationIdentifier = @"LMOnboardingViewController";
//		self.restorationClass = [LMGuideViewPagerController class];
	}
	return self;
}

+ (UIViewController*)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents
														   coder:(NSCoder *)coder {
	
	NSInteger currentPageNumber = [coder decodeIntegerForKey:LMOnboardingViewControllerIndexKey];
	
	LMGuideViewPagerController *controller = [LMGuideViewPagerController new];
	controller.guideMode = GuideModeOnboarding;
	controller.currentPageNumber = currentPageNumber;
	
	NSLog(@"Path %@", identifierComponents);
	
	return controller;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
	[coder encodeInteger:self.currentPageNumber forKey:LMOnboardingViewControllerIndexKey];
	
	[super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
	[super decodeRestorableStateWithCoder:coder];
}

- (void)loadView {
	[super loadView];
	
	self.view = [[UIView alloc]initWithFrame:self.view.frame];
	self.view.backgroundColor = [UIColor whiteColor];
}

- (BOOL)prefersStatusBarHidden{
	return YES;
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	BOOL willBeLandscape = size.width > size.height;
	if(![LMLayoutManager isiPad]){
		self.backgroundImageView.image = [UIImage imageNamed:willBeLandscape ? @"lignite_background_landscape.png" : @"lignite_background_portrait.png"];
	}
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.layoutManager = [LMLayoutManager sharedLayoutManager];
	[self.layoutManager addDelegate:self];

	switch(self.guideMode){
		case GuideModeOnboarding: {
			self.titleArray = [[NSArray alloc]initWithObjects:
							   @"OnboardingWelcomeTitle",
//							   @"OnboardingKickstarterLoginTitle",
							   @"OnboardingMusicPermissionTitle",
							   @"OnboardingTutorialTitle",
							    nil];
	
			self.descriptionArray = [[NSArray alloc]initWithObjects:
									 @"OnboardingWelcomeDescription",
//									 @"OnboardingKickstarterLoginDescription",
									 @"OnboardingMusicPermissionDescription",
									 @"OnboardingTutorialDescription",
							    nil];
			
			self.screenshotsArray = [[NSArray alloc]initWithObjects:
									 @"icon_no_cover_art_75.png",
//									 @"icon_kickstarter_bw.png",
									 @"icon_library_access.png",
									 @"icon_rocket_ship.png",
									  nil];
			
			self.buttonNamesArray = [[NSArray alloc]initWithObjects:
									 @"LetsGo",
//									 @"LogMeIn",
//									 @"HitMeWithIt",
									 @"SoundsGood",
									 @"JumpRightIn",
							    nil];
			
			break;
		}
		case GuideModeMusicPermissionDenied: {
			self.currentPageNumber = 0;
			
			self.titleArray = [[NSArray alloc]initWithObjects:
							   @"OnboardingUserIsGutlessTitle"
							   , nil];
			
			self.descriptionArray = [[NSArray alloc]initWithObjects:
									 @"OnboardingUserIsGutlessDescription"
							   , nil];
			
			self.screenshotsArray = [[NSArray alloc]initWithObjects:
									 @"no_library_access.png"
									 , nil];
			
			self.buttonNamesArray = [[NSArray alloc]initWithObjects:
									 @"OkDone"
							   , nil];
			break;
		}
	}
	
	self.amountOfPages = self.titleArray.count;
	
	self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
	
//	self.pageController.dataSource = self;
	[[self.pageController view] setFrame:[[self view] bounds]];
	
	LMGuideViewController *initialViewController = [self viewControllerAtIndex:self.currentPageNumber];
	
	NSArray *viewControllers = [NSArray arrayWithObject:initialViewController];
	
	[self.pageController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
	
	self.backgroundImageView = [UIImageView newAutoLayoutView];
	self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
	self.backgroundImageView.image = [UIImage imageNamed:self.layoutManager.isLandscape ? @"lignite_background_landscape.png" : @"lignite_background_portrait.png"];
	self.backgroundImageView.clipsToBounds = YES;
	if([LMLayoutManager isiPad]){
		self.backgroundImageView.image = [UIImage imageNamed:@"lignite_background_ipad.png"];
	}
	[self.view addSubview:self.backgroundImageView];
	
	[self.backgroundImageView autoPinEdgesToSuperviewEdges];
	
//	UIView *testView = [UIView newAutoLayoutView];
//	testView.backgroundColor = [UIColor blueColor];
//	[self.view addSubview:testView];
	
	[self addChildViewController:self.pageController];
	[self.view addSubview:self.pageController.view];
	[self.pageController didMoveToParentViewController:self];
}

- (void)didReceiveMemoryWarning {
	
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
	
}

- (LMGuideViewController *)viewControllerAtIndex:(NSUInteger)index {
	
	LMGuideViewController *childViewController = [LMGuideViewController new];
	
	childViewController.amountOfPages = self.amountOfPages;
	childViewController.guideMode = self.guideMode;
	childViewController.index = (int)index;
	childViewController.contentTitle = NSLocalizedString([self.titleArray objectAtIndex:index], nil);
	childViewController.contentDescription = NSLocalizedString([self.descriptionArray objectAtIndex:index], nil);
	childViewController.screenshotImage = [UIImage imageNamed:[self.screenshotsArray objectAtIndex:index]];
	childViewController.buttonTitle = NSLocalizedString([self.buttonNamesArray objectAtIndex:index], nil);
	childViewController.sourcePagerController = self.pageController;
	childViewController.coreViewController = self.coreViewController;
	childViewController.rootViewPagerController = self;
	
	if(index < self.amountOfPages-1){
		childViewController.nextViewController = [self viewControllerAtIndex:index+1];
	}
	
	return childViewController;
	
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
	
	NSUInteger index = [(LMGuideViewController *)viewController index];
	
	if (index == 0) {
		return nil;
	}
	
	// Decrease the index by 1 to return
	index--;
	
	return [self viewControllerAtIndex:index];
	
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
	
	NSUInteger index = [(LMGuideViewController *)viewController index];
	
	index++;
	
	if (index == self.amountOfPages) {
		return nil;
	}
	
	return [self viewControllerAtIndex:index];
	
}

@end
