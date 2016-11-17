//
//  LNTutorialViewController.h
//  Lignite
//
//  Created by Edwin Finch on 11/8/15.
//  Copyright © 2015 Edwin Finch. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMTutorialViewPagerController.h"

@interface LMTutorialViewController : UIViewController

@property UIPageViewController *sourcePagerController;

@property LMTutorialViewController *nextViewController;

@property int index;
@property NSString *contentTitle;
@property NSString *contentDescription;
@property UIImage *screenshotImage;
@property NSString *buttonTitle;
@property int screenshotViewHeight;
@property int forcedScreenshotHeight;
@property (strong, nonatomic) UILabel *screenNumber;

@end
