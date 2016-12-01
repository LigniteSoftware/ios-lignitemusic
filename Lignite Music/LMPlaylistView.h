//
//  LMPlaylistView.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/9/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMCoreViewController.h"

@interface LMPlaylistView : UIView

@property LMCoreViewController *coreViewController;

- (void)setup;
- (void)reloadSourceSelectorInfo;

@end
