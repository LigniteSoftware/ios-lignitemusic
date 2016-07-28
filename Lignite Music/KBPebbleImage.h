//
//  KBPebbleImage.h
//  pebbleremote
//
//  Created by Katharine Berry on 27/05/2013.
//  Copyright (c) 2013 Katharine Berry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface KBPebbleImage : NSObject

+ (UIImage*)ditherImageForPebble:(UIImage*)image withColourPalette:(BOOL)colourPalette;

@end
