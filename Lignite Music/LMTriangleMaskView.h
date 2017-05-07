//
//  LMTriangleMaskView.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/30/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LMTriangleMaskView : UIView

/**
 The direction in which the triangle mask should point.

 - LMTriangleMaskDirectionUpwards: Tip pointing upwards.
 - LMTriangleMaskDirectionRight: Tip pointing towards the right side.
 - LMTriangleMaskDirectionDownwards: Tip pointing downwards.
 - LMTriangleMaskDirectionLeft: Tip pointing left.
 */
typedef NS_ENUM(NSInteger, LMTriangleMaskDirection) {
	LMTriangleMaskDirectionUpwards = 0,
	LMTriangleMaskDirectionRight,
	LMTriangleMaskDirectionDownwards,
	LMTriangleMaskDirectionLeft
};

/**
 The triangle mask direction to apply.
 */
@property LMTriangleMaskDirection maskDirection;

/**
 The colour of the triangle.
 */
@property UIColor *triangleColour;

/**
 Setup the triangle mask view.
 */
- (void)setup;

/**
 The path of the triangle mask view based on its current frame.

 @return The path.
 */
- (UIBezierPath*)path;

@end
