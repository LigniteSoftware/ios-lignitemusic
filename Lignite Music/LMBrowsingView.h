//
//  LMBrowsingView.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/11/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMCoreViewController.h"
#import "LMMusicTrackCollection.h"

@interface LMBrowsingView : UIView

@property LMCoreViewController *rootViewController;

@property NSArray<LMMusicTrackCollection*> *musicTrackCollections;

@property BOOL showingDetailView;

- (void)setup;
- (void)reloadSourceSelectorInfo;
- (void)dismissDetailView;

@end
