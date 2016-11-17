//
//  LNTutorialViewPagerController.m
//  Lignite
//
//  Created by Edwin Finch on 11/7/15.
//  Copyright © 2015 Edwin Finch. All rights reserved.
//

#import "LMTutorialViewPagerController.h"
#import "LMTutorialViewController.h"
#import "LMColour.h"

@interface LMTutorialViewPagerController ()

@property NSArray *titleArray, *descriptionArray, *screenshotsArray, *buttonNamesArray;
@property int screenshotHeight;

@end

@implementation LMTutorialViewPagerController

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
	
	/*
	 "OnboardingWelcomeTitle" = "Welcome to Lignite Music";
	 "OnboardingWelcomeDescription" = "We hope you have a great time!";
	 
	 "OnboardingMusicPermissionTitle" = "We're gonna jam with you!";
	 "OnboardingMusicPermissionDescription" = "Please accept the music request.";
	 
	 "OnboardingPebblePermissionTitle" = "Pebble...?";
	 "OnboardingPebblePermissionDescription" = "Pebble life.";
	 
	 "OnboardingTutorialTitle" = "Tutorial. Maybe.";
	 "OnboardingTutorialDescription" = "It sucks";
	 */
	
	self.titleArray = [[NSArray alloc]initWithObjects:
					   @"OnboardingWelcomeTitle",
					   @"OnboardingKickstarterLoginTitle",
					   @"OnboardingMusicPermissionTitle",
					   @"OnboardingPebblePermissionTitle",
					   @"OnboardingTutorialTitle",
					   @"OnboardingThanksTitle"
					   , nil];
	
	self.descriptionArray = [[NSArray alloc]initWithObjects:
							 @"OnboardingWelcomeDescription",
							 @"OnboardingKickstarterLoginDescription",
							 @"OnboardingMusicPermissionDescription",
							 @"OnboardingPebblePermissionDescription",
							 @"OnboardingTutorialDescription",
							 @"OnboardingThanksDescription"
					   , nil];
	
	self.screenshotsArray = [[NSArray alloc]initWithObjects:
							 @"icon_no_cover_art.png",
							 @"icon_no_cover_art.png",
							 @"onboarding_library_access.png",
							 @"onboarding_bluetooth.png",
							 @"icon_no_cover_art.png",
							 @"onboarding_us.png"
							 , nil];
	
	self.buttonNamesArray = [[NSArray alloc]initWithObjects:
							 @"LetsGo",
							 @"LogMeIn",
							 @"HitMeWithIt",
							 @"SoundsGood",
							 @"OpenTutorial",
							 @"AwesomeThanks"
					   , nil];
	
	int smallestHeight = 20000;
	for(int i = 0; i < AMOUNT_OF_TUTORIAL_SCREENS-1; i++){
		LMTutorialViewController *controller = [self viewControllerAtIndex:i];
		[controller viewDidLoad];
		if(controller.screenshotViewHeight < smallestHeight){
			smallestHeight = controller.screenshotViewHeight;
		}
	}
	self.screenshotHeight = smallestHeight;
	
//	UIPageControl *pageControl = [UIPageControl appearanceWhenContainedInInstancesOfClasses:@[[LMTutorialViewPagerController class]]];
//	pageControl.pageIndicatorTintColor = [UIColor darkGrayColor];
//	pageControl.currentPageIndicatorTintColor = [LMColour ligniteRedColour];
	//pageControl.backgroundColor = [UIColor lightGrayColor];
	
	self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
	
	self.pageController.dataSource = self;
	[[self.pageController view] setFrame:[[self view] bounds]];
	
	LMTutorialViewController *initialViewController = [self viewControllerAtIndex:0];
	
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

- (LMTutorialViewController *)viewControllerAtIndex:(NSUInteger)index {
	
	LMTutorialViewController *childViewController = [[LMTutorialViewController alloc] init];
	childViewController.index = (int)index;
	childViewController.contentTitle = NSLocalizedString([self.titleArray objectAtIndex:index], nil);
	childViewController.contentDescription = NSLocalizedString([self.descriptionArray objectAtIndex:index], nil);
	childViewController.screenshotImage = [UIImage imageNamed:[self.screenshotsArray objectAtIndex:index]];
	childViewController.buttonTitle = NSLocalizedString([self.buttonNamesArray objectAtIndex:index], nil);
	childViewController.forcedScreenshotHeight = self.screenshotHeight;
	
	return childViewController;
	
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
	
	NSUInteger index = [(LMTutorialViewController *)viewController index];
	
	if (index == 0) {
		return nil;
	}
	
	// Decrease the index by 1 to return
	index--;
	
	return [self viewControllerAtIndex:index];
	
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
	
	NSUInteger index = [(LMTutorialViewController *)viewController index];
	
	index++;
	
	if (index == AMOUNT_OF_TUTORIAL_SCREENS) {
		return nil;
	}
	
	return [self viewControllerAtIndex:index];
	
}

//- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray<UIViewController *> *)pendingViewControllers{
//	LMTutorialViewController *pageContentView = (LMTutorialViewController*) pendingViewControllers[0];
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
