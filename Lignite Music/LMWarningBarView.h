//
//  LMWarningBarView.h
//  Lignite Music
//
//  Created by Edwin Finch on 12/18/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMView.h"
#import "LMWarning.h"

@interface LMWarningBarView : LMView

/**
 Sets a warning for display. Only one warning can be displayed at a time.

 @param warning The warning to display.
 */
- (void)setWarning:(LMWarning*)warning;

@end
