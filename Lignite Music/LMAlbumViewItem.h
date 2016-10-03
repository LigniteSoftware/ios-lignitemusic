//
//  LMAlbumViewItem.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/6/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LMAlbumViewItem;

@protocol LMAlbumViewItemDelegate <NSObject>

- (void)clickedAlbumViewItem:(LMAlbumViewItem*)item;
- (void)clickedPlayButtonOnAlbumViewItem:(LMAlbumViewItem*)item;

@end

@interface LMAlbumViewItem : UIView

@property MPMediaItem *item;
@property NSUInteger collectionIndex;

- (void)updateContentsWithMediaItem:(MPMediaItem*)item andNumberOfItems:(NSInteger)numberOfItems;
- (void)setupWithAlbumCount:(NSUInteger)numberOfItems andDelegate:(id)delegate;
- (id)initWithMediaItem:(MPMediaItem*)item;

@end
