//
//  LMSettingsView.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/21/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LMSettingsView : UIView

@property UIViewController *coreViewController;

@property UIViewController *settingsViewController;

- (void)prepareForDestroy;

@end
