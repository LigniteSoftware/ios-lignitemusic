//
//  LNTutorialViewPagerController.m
//  Lignite
//
//  Created by Edwin Finch on 11/7/15.
//  Copyright © 2015 Edwin Finch. All rights reserved.
//

#import "LMGuideViewPagerController.h"
#import "LMGuideViewController.h"
#import "LMColour.h"

@interface LMGuideViewPagerController ()

@property NSArray *titleArray, *descriptionArray, *screenshotsArray, *buttonNamesArray;

@property NSInteger amountOfPages;

@end

@implementation LMGuideViewPagerController

- (void)loadView {
	[super loadView];
	
	self.view = [[UIView alloc]initWithFrame:self.view.frame];
	self.view.backgroundColor = [UIColor whiteColor];
}

-(BOOL)prefersStatusBarHidden{
	return YES;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	switch(self.guideMode){
		case GuideModeOnboarding: {
			self.amountOfPages = 5;
			
			self.titleArray = [[NSArray alloc]initWithObjects:
							   @"OnboardingWelcomeTitle",
		//					   @"OnboardingKickstarterLoginTitle",
							   @"OnboardingMusicPermissionTitle",
							   @"OnboardingPebblePermissionTitle",
							   @"OnboardingTutorialTitle",
							   @"OnboardingThanksTitle"
							   , nil];
			
			self.descriptionArray = [[NSArray alloc]initWithObjects:
									 @"OnboardingWelcomeDescription",
		//							 @"OnboardingKickstarterLoginDescription",
									 @"OnboardingMusicPermissionDescription",
									 @"OnboardingPebblePermissionDescription",
									 @"OnboardingTutorialDescription",
									 @"OnboardingThanksDescription"
							   , nil];
			
			self.screenshotsArray = [[NSArray alloc]initWithObjects:
									 @"icon_no_cover_art.png",
		//							 @"icon_no_cover_art.png",
									 @"onboarding_library_access.png",
									 @"onboarding_bluetooth.png",
									 @"tutorial_browsing.png",
									 @"onboarding_us.png"
									 , nil];
			
			self.buttonNamesArray = [[NSArray alloc]initWithObjects:
									 @"LetsGo",
		//							 @"LogMeIn",
									 @"HitMeWithIt",
									 @"SoundsGood",
									 @"OpenTutorial",
									 @"AwesomeThanks"
							   , nil];
			
			break;
		}
		case GuideModeTutorial: {
			self.amountOfPages = 4;
			
			self.titleArray = [[NSArray alloc]initWithObjects:
							   @"TutorialBrowsingTitle",
							   @"TutorialBottomControlsTitle",
							   @"TutorialPlayingControlsTitle",
							   @"TutorialPebbleAppTitle"
							   , nil];
			
			self.descriptionArray = [[NSArray alloc]initWithObjects:
									 @"TutorialBrowsingDescription",
									 @"TutorialBottomControlsDescription",
									 @"TutorialPlayingControlsDescription",
									 @"TutorialPebbleAppDescription"
							   , nil];
			
			self.screenshotsArray = [[NSArray alloc]initWithObjects:
									 @"tutorial_browsing.png",
									 @"tutorial_bottom_tabs.png",
									 @"tutorial_now_playing.png",
									 @"tutorial_pebble.png"
									 , nil];
			
			self.buttonNamesArray = [[NSArray alloc]initWithObjects:
									 @"Cool",
									 @"Sweet",
									 @"WhatsNext",
									 @"EndTutorial"
							   , nil];
			break;
		}
		case GuideModeMusicPermissionDenied: {
			self.amountOfPages = 1;
			
			self.titleArray = [[NSArray alloc]initWithObjects:
							   @"OnboardingUserIsGutlessTitle"
							   , nil];
			
			self.descriptionArray = [[NSArray alloc]initWithObjects:
									 @"OnboardingUserIsGutlessDescription"
							   , nil];
			
			self.screenshotsArray = [[NSArray alloc]initWithObjects:
									 @"icon_no_cover_art.png"
									 , nil];
			
			self.buttonNamesArray = [[NSArray alloc]initWithObjects:
									 @"OkDone"
							   , nil];
			break;
		}
	}
	
	self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
	
//	self.pageController.dataSource = self;
	[[self.pageController view] setFrame:[[self view] bounds]];
	
	LMGuideViewController *initialViewController = [self viewControllerAtIndex:0];
	
	NSArray *viewControllers = [NSArray arrayWithObject:initialViewController];
	
	[self.pageController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
	
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

//- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray<UIViewController *> *)pendingViewControllers{
//	LMGuideViewController *pageContentView = (LMGuideViewController*) pendingViewControllers[0];
//	self.pageControl.currentPage = pageContentView.index;
//}

//- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
//	// The number of items reflected in the page indicator.
//	return AMOUNT_OF_TUTORIAL_SCREENS;
//}
//
//- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
//	// The selected item reflected in the page indicator.
//	return 0;
//}

@end
