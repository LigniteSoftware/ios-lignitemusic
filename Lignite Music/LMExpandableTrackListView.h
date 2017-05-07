//
//  LMExpandableTrackListView.h
//  Lignite Music
//
//  Created by Edwin Finch on 5/7/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LMMusicPlayer.h"
#import "LMView.h"

@interface LMExpandableTrackListView : LMView

/**
 The collection view which actually displays the data.
 */
@property UICollectionView *collectionView;

/**
 The music type associated with this expandable track list view.
 */
@property LMMusicType musicType;

/**
 The music track collection associated with this track list view.
 */
@property LMMusicTrackCollection *musicTrackCollection;

/**
 The flow layout associated.
 */
@property id flowLayout;

+ (CGSize)currentItemSize;
+ (CGSize)sizeForAmountOfItems:(NSInteger)amountOfItems;

@end
