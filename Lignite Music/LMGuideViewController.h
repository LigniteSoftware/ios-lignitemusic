//
//  LNTutorialViewController.h
//  Lignite
//
//  Created by Edwin Finch on 11/8/15.
//  Copyright © 2015 Edwin Finch. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMGuideViewPagerController.h"

@interface LMGuideViewController : UIViewController

@property UIPageViewController *sourcePagerController;

@property LMGuideViewController *nextViewController;

@property NSUInteger amountOfPages;
@property GuideMode guideMode;
@property int index;
@property NSString *contentTitle;
@property NSString *contentDescription;
@property UIImage *screenshotImage;
@property NSString *buttonTitle;
@property (strong, nonatomic) UILabel *screenNumber;

@end
