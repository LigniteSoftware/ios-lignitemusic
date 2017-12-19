//
//  LMSearchViewController.h
//  Lignite Music
//
//  Created by Edwin Finch on 12/7/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMDynamicSearchView.h"

@protocol LMSearchViewControllerResultDelegate <NSObject>

/**
 A search entry was tapped with a certain persistent ID, associated to a music type.

 @param persistentID The persistent ID of the item that was tapped, related to the music type.
 @param musicType The music type of the item that was tapped, which determines the source of the persistent ID.
 */
- (void)searchEntryTappedWithPersistentID:(MPMediaEntityPersistentID)persistentID forMusicType:(LMMusicType)musicType;

@end

@interface LMSearchViewController : UIViewController

/**
 The delegate for when a search term is tapped.
 */
@property id<LMSearchViewControllerResultDelegate> delegate;

@end
