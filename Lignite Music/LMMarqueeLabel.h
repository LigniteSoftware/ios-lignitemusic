//
//  LMMarqueeLabel.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/6/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <MarqueeLabel/MarqueeLabel.h>

@interface LMMarqueeLabel : MarqueeLabel

/**
 Gets a HelveticaNeue-Light font to fit a certain height.

 @param height The height to fit.
 @return The font which will fit it.
 */
+ (UIFont*)fontToFitHeight:(CGFloat)height;

@end
