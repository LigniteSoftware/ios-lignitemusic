//
//  LMGrabberView.h
//  Lignite Music
//
//  Created by Edwin Finch on 12/13/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMView.h"

@interface LMGrabberView : LMView

/**
 The icon to use. If nil on first subview layout, it will set itself to the flat bar.
 */
@property UIImage *grabberIcon;

@end
