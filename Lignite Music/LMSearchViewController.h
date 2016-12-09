//
//  LMSearchViewController.h
//  Lignite Music
//
//  Created by Edwin Finch on 12/7/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMSearchView.h"

@interface LMSearchViewController : UIViewController

/**
 The delegate for when a search term is selected.
 */
@property id<LMSearchSelectedDelegate> searchSelectedDelegate;

@end
