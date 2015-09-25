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
#define IS_PORTRAIT  UIDeviceOrientationIsPortrait(dDeviceOrientation)
#define IS_LANDSCAPE UIDeviceOrientationIsLandscape(dDeviceOrientation)
#define IS_FACE_UP    dDeviceOrientation == UIDeviceOrientationFaceUp   ? YES : NO
#define IS_FACE_DOWN  dDeviceOrientation == UIDeviceOrientationFaceDown ? YES : NO
#define LIGNITE_COLOUR [UIColor colorWithRed:0.82 green:0.17 blue:0.16 alpha:1.0]
#define WINDOW_FRAME [[[[UIApplication sharedApplication] windows] objectAtIndex:0] frame]

#endif /* LMExtras_h */
