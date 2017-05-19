//
//  LMScrollView.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/26/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMLayoutManager.h"

@interface LMScrollView : UIScrollView

/**
 Should adapt for width. Default is NO. If YES, it will adapt for width instead of height.
 */
@property BOOL adaptForWidth;

/**
 The content offset which was preserved.
 */
@property CGPoint preservedContentOffset;

/**
 Reload the size of the scroll view.
 */
- (void)reload;

@end
