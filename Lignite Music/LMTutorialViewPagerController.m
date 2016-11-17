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

@property UIPageControl *pageControl;

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
					   @"OnboardingMusicPermissionTitle",
					   @"OnboardingPebblePermissionTitle",
					   @"OnboardingTutorialTitle",
					   @"tutorial_settings_screen", @"tutorial_other_actions", @"tutorial_backer_login", @"tutorial_thanks"
					   , nil];
	
	self.descriptionArray = [[NSArray alloc]initWithObjects:
							 @"OnboardingWelcomeDescription",
							 @"OnboardingMusicPermissionDescription",
							 @"OnboardingPebblePermissionDescription",
							 @"OnboardingTutorialDescription",
	
							 @"tutorial_settings_screen_description", @"tutorial_other_actions_description", @"tutorial_backer_login_description", @"tutorial_thanks_description"
					   , nil];
	
	self.screenshotsArray = [[NSArray alloc]initWithObjects:
							 @"icon_no_cover_art.png",
							 @"onboarding_library_access.png",
							 @"onboarding_bluetooth.png",
							 @"onboarding_us.png",
							 @"tutorial_settings_screen.png", @"tutorial_other_actions.png", @"tutorial_backer_login.png", @"tutorial_thanks.png"
							 , nil];
	
	self.buttonNamesArray = [[NSArray alloc]initWithObjects:
					   @"LetsGo", @"HitMeWithIt", @"SoundsGood", @"OpenTutorial",
					   @"vertical-scroll.png", @"single-tap.png", @"vertical-scroll.png", @"signatures_combined.png"
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
	
	self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height/2, self.view.frame.size.width, 50)]; // your position
	self.pageControl.pageIndicatorTintColor = [UIColor darkGrayColor];
	self.pageControl.numberOfPages = 4;
	self.pageControl.currentPageIndicatorTintColor = [LMColour ligniteRedColour];

	[self.view addSubview: self.pageControl];
	
	NSLog(@"Got %@", NSStringFromCGRect(self.pageControl.frame));
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

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray<UIViewController *> *)pendingViewControllers{
	LMTutorialViewController *pageContentView = (LMTutorialViewController*) pendingViewControllers[0];
	self.pageControl.currentPage = pageContentView.index;
}

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
