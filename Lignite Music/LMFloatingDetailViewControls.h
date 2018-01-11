//
//  LMFloatingDetailViewControls.h
//  Lignite Music
//
//  Created by Edwin Finch on 1/11/18.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import "LMView.h"
#import "LMFloatingDetailViewButton.h"

@interface LMFloatingDetailViewControls : LMView

/**
 Whether to include the back button. Default is NO.
 */
@property BOOL showingBackButton;

/**
 The delegate for button presses.
 */
@property id<LMFloatingDetailViewButtonDelegate> delegate;

@end
