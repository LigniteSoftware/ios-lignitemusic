//
//  LMSettingsViewController.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/24/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMCoreViewController.h"

#define APPLE_WATCH_RAW_SECTION_NUMBER 2
#define APPLE_WATCH_FIXED_SECTION_NUMBER 69

#define NUMBER_OF_SETTING_SECTIONS_WITHOUT_APPLE_WATCH 4

@interface LMSettingsViewController : UIViewController

@property LMCoreViewController *coreViewController;

@end
