//
//  LMTutorialHeaderView.h
//  Lignite Music
//
//  Created by Edwin Finch on 1/20/18.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import "LMView.h"

@protocol LMTutorialHeaderViewDelegate<NSObject>

/**
 The tutorial header's button was tapped, the intro video should now begin.
 */
- (void)tutorialHeaderViewButtonTapped;

@end

@interface LMTutorialHeaderView : LMView

/**
 The delegate.
 */
@property id<LMTutorialHeaderViewDelegate> delegate;

@end
