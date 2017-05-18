//
//  LNTutorialViewPagerController.h
//  Lignite
//
//  Created by Edwin Finch on 11/7/15.
//  Copyright © 2015 Edwin Finch. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMCoreViewController.h"

@class LMGuideViewController;

@interface LMGuideViewPagerController : UIViewController <UIPageViewControllerDataSource>

typedef enum {
	GuideModeOnboarding = 0,
	GuideModeMusicPermissionDenied
} GuideMode;

@property (strong, nonatomic) UIPageViewController *pageController;
@property GuideMode guideMode;
@property LMCoreViewController *coreViewController;
@property NSInteger currentPageNumber;

- (LMGuideViewController *)viewControllerAtIndex:(NSUInteger)index;

@end
