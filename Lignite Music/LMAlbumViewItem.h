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

- (void)setupWithAlbumCount:(NSUInteger)numberOfItems;
- (id)initWithMediaItem:(MPMediaItem*)item withAlbumCount:(NSInteger)count;

@end
