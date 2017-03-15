//
//  LMBrowsingDetailViewController.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/25/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMBrowsingDetailView.h"

@interface LMBrowsingDetailViewController : UIViewController

/**
 The browsing detail view which is actually attached to this controller's view.
 */
@property LMBrowsingDetailView *browsingDetailView;

/**
 The next detail view controller in sequence, if one exists. For example, genres -> rap (current) -> album (nextDetailViewController).
 */
@property LMBrowsingDetailViewController *nextDetailViewController;

@end
