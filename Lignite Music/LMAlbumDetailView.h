//
//  LMAlbumDetailView.h
//  Lignite Music
//
//  Created by Edwin Finch on 9/28/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMAlbumViewController.h"

@interface LMAlbumDetailView : UIView

@property LMAlbumViewController *rootViewController;

- (void)setup;
- (id)initWithMediaItemCollection:(MPMediaItemCollection*)collection;

@end
