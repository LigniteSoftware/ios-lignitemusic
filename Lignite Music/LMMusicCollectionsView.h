//
//  LMMusicCollectionsView.h
//  Lignite Music
//
//  Created by Edwin Finch on 5/15/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMView.h"
#import "LMMusicPlayer.h"

@class LMMusicCollectionsView;

@protocol LMMusicCollectionsViewDelegate <NSObject>
@required

/**
 A certain music collection was tapped at an index.

 @param index The index of the music collection which was tapped.
 @param collectionsView The collections view associated.
 */
- (void)musicCollectionTappedAtIndex:(NSInteger)index forMusicCollectionsView:(LMMusicCollectionsView*)collectionsView;

@end

@interface LMMusicCollectionsView : LMView

/**
 The actual collection view for displaying collections in a compact method.
 */
@property UICollectionView *collectionView;

/**
 The track collections for the music collections view to display.
 */
@property NSArray<LMMusicTrackCollection*> *trackCollections;

/**
 The delegate.
 */
@property id<LMMusicCollectionsViewDelegate> delegate;

/**
 The size of an item within the music collection view, based off of current data from LMLayoutManager.

 @return The size of an item.
 */
+ (CGSize)itemSize;

@end
