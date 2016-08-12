//
//  KBPebbleImage.h
//  pebbleremote
//
//  Created by Katharine Berry on 27/05/2013.
//  Copyright (c) 2013 Katharine Berry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface LMPebbleImage : NSObject

+ (UIImage*)ditherImage:(UIImage*)originalImage
               withSize:(CGSize)size
          forTotalParts:(uint8_t)totalParts
        withCurrentPart:(uint8_t)currentPart
        isBlackAndWhite:(BOOL)blackAndWhite
           isRoundWatch:(BOOL)isRound;
@end
