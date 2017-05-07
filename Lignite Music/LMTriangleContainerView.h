//
//  LMTriangleContainerView.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/30/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMTriangleMaskView.h"

@interface LMTriangleContainerView : UIView

/**
 The triangle mask direction to apply.
 */
@property LMTriangleMaskDirection maskDirection;

/**
 The colour of the triangle.
 */
@property UIColor *triangleColour;

@end
