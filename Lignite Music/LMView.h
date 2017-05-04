//
//  LMView.h
//  Lignite Music
//
//  Created by Edwin Finch on 12/1/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMLayoutManager.h"

@class LMView;

@interface LMView : UIView

/**
 Whether or not the constraints of this view have been lain out.
 */
@property BOOL didLayoutConstraints;

@end
