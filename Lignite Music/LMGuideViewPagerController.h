//
//  LNTutorialViewPagerController.h
//  Lignite
//
//  Created by Edwin Finch on 11/7/15.
//  Copyright © 2015 Edwin Finch. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LMGuideViewController;

@interface LMGuideViewPagerController : UIViewController <UIPageViewControllerDataSource>

typedef enum {
	GuideModeOnboarding = 0,
	GuideModeTutorial,
	GuideModeMusicPermissionDenied
} GuideMode;

@property (strong, nonatomic) UIPageViewController *pageController;
@property GuideMode guideMode;

- (LMGuideViewController *)viewControllerAtIndex:(NSUInteger)index;

@end
