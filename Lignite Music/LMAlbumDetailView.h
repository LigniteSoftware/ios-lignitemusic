//
//  LMAlbumDetailView.h
//  Lignite Music
//
//  Created by Edwin Finch on 9/28/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMAlbumView.h"

@interface LMAlbumDetailView : UIView

- (void)setup;
- (id)initWithMediaItemCollection:(MPMediaItemCollection*)collection;

@end
