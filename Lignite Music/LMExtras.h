//
//  LMExtras.h
//  Lignite Music
//
//  Created by Edwin Finch on 9/24/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#ifndef LMExtras_h
#define LMExtras_h

//Device orientation checks
#define DEVICE_ORIENTATION [[UIDevice currentDevice] orientation]
#define IS_PORTRAIT  self.frame.size.height > self.frame.size.width
#define IS_LANDSCAPE UIDeviceOrientationIsLandscape(DEVICE_ORIENTATION)
#define IS_FACE_UP    DEVICE_ORIENTATION == UIDeviceOrientationFaceUp   ? YES : NO
#define IS_FACE_DOWN  DEVICE_ORIENTATION == UIDeviceOrientationFaceDown ? YES : NO
#define WINDOW_FRAME [[[[UIApplication sharedApplication] windows] objectAtIndex:0] frame]

//Language fixes
#define NSTextAlignmentCentre NSTextAlignmentCenter

//Version checks
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#endif /* LMExtras_h */
