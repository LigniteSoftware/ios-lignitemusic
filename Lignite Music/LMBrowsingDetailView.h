//
//  LMBrowsingDetailView.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/12/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMCoreViewController.h"
#import "LMMusicPlayer.h"
#import "LMBrowsingView.h"
#import "LMTableView.h"
#ifdef SPOTIFY
#import "Spotify.h"
#endif

@interface LMBrowsingDetailView : UIView

@property LMTableView *tableView;

/**
 The root view controller.
 */
@property LMCoreViewController *rootViewController;

/**
 The music tracks associated with this LMBrowsingDetailView.
 */
@property LMMusicTrackCollection *musicTrackCollection;

/**
 The music type/collection type that's associated with this detail view.
 */
@property LMMusicType musicType;

/**
 Setup this view.
 */
- (void)setup;

@end
