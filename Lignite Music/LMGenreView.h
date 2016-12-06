//
//  LMGenreView.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/13/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMCoreViewController.h"
#import "LMBrowsingView.h"

@interface LMGenreView : UIView

@property LMCoreViewController *coreViewController;

@property LMBrowsingView *browsingView;

- (void)setup;
- (void)reloadSourceSelectorInfo;

@end
