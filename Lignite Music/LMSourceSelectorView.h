//
//  LMSourceSelector.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/14/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMSource.h"

@interface LMSourceSelectorView : UIView

/**
 The array of sources to expose to the user.
 */
@property NSArray<LMSource*> *sources;

- (void)setup;

@end
