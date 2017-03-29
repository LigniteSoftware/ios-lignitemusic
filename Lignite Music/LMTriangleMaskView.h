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
 Whether or not to point the triangle upwards.
 */
@property BOOL upwards;

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
