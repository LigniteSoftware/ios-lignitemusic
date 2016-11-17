//
//  LNTutorialViewPagerController.h
//  Lignite
//
//  Created by Edwin Finch on 11/7/15.
//  Copyright © 2015 Edwin Finch. All rights reserved.
//

#import <UIKit/UIKit.h>

#define AMOUNT_OF_TUTORIAL_SCREENS 8

@interface LMTutorialViewPagerController : UIViewController <UIPageViewControllerDataSource>

@property (strong, nonatomic) UIPageViewController *pageController;

@end
