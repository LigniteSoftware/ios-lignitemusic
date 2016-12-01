//
//  LMAlbumViewItem.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/6/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMMusicTrack.h"
#import "LMButton.h"

@class LMAlbumViewItem;

@protocol LMAlbumViewItemDelegate <NSObject>

- (void)clickedAlbumViewItem:(LMAlbumViewItem*)item;
- (void)clickedPlayButtonOnAlbumViewItem:(LMAlbumViewItem*)item;

@end

@interface LMAlbumViewItem : UIView

@property LMMusicTrack *track;
@property NSUInteger collectionIndex;
@property LMButton *playButton;

- (void)updateContentsWithMusicTrack:(LMMusicTrack*)track andNumberOfItems:(NSInteger)numberOfItems;
- (void)setupWithAlbumCount:(NSUInteger)numberOfItems andDelegate:(id)delegate;
- (id)initWithMusicTrack:(LMMusicTrack*)track;

@end
