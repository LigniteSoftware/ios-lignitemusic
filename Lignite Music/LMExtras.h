//
//  LMExtras.h
//  Lignite Music
//
//  Created by Edwin Finch on 9/24/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#ifndef LMExtras_h
#define LMExtras_h

// check device orientation
#define DEVICE_ORIENTATION [[UIDevice currentDevice] orientation]
#define IS_PORTRAIT  self.frame.size.height > self.frame.size.width
#define IS_LANDSCAPE UIDeviceOrientationIsLandscape(DEVICE_ORIENTATION)
#define IS_FACE_UP    DEVICE_ORIENTATION == UIDeviceOrientationFaceUp   ? YES : NO
#define IS_FACE_DOWN  DEVICE_ORIENTATION == UIDeviceOrientationFaceDown ? YES : NO
#define WINDOW_FRAME [[[[UIApplication sharedApplication] windows] objectAtIndex:0] frame]

#endif /* LMExtras_h */
