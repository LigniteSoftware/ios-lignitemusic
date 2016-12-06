//
//  LMAlbumViewController.h
//  Lignite Music
//
//  Created by Edwin Finch on 9/26/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMCoreViewController.h"
#import "LMBrowsingView.h"

@interface LMArtistView : UIView

@property LMCoreViewController *coreViewController;

@property LMBrowsingView *browsingView;

- (void)reloadSourceSelectorInfo;
- (void)setup;

@end
