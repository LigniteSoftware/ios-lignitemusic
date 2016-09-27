//
//  LMAlbumViewItem.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/6/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LMAlbumViewItem : UIView

- (void)load;
- (id)initWithMediaItem:(MPMediaItem*)item withAlbumCount:(NSInteger)count;

@end
