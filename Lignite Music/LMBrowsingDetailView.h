//
//  LMBrowsingDetailView.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/12/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMMusicPlayer.h"
#import "LMBrowsingView.h"

@interface LMBrowsingDetailView : UIView

/**
 The music tracks associated with this LMBrowsingDetailView.
 */
@property LMMusicTrackCollection *musicTrackCollection;

/**
 Setup this view.
 */
- (void)setup;

@end
