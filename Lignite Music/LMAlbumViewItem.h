//
//  LMAlbumViewItem.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/6/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LMAlbumViewItem : UIView

@property BOOL hasLoaded;
@property MPMediaItem *item;
@property NSUInteger collectionIndex;

- (void)setupWithAlbumCount:(NSUInteger)numberOfItems andDelegate:(id)delegate;
- (id)initWithMediaItem:(MPMediaItem*)item withAlbumCount:(NSInteger)count;

@end
