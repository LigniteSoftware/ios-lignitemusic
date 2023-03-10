//
//  LMCollectionViewFlowLayout.h
//  Lignite Music
//
//  Created by Edwin Finch on 5/5/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMMusicPlayer.h"
#import "LMEmbeddedDetailView.h"

#define LMNoDetailViewSelected -1
#define COMPACT_VIEW_SPACING_BETWEEN_ITEMS 15

@interface LMCollectionViewFlowLayout : UICollectionViewFlowLayout

/**
 The display mode for the detail view.

 - LMDetailViewDisplayModeNone: Do not display the detail view at all.
 - LMDetailViewDisplayModeCurrentIndex: Display the detail view based off the current index.
 - LMDetailViewDisplayModePreviousIndex: Display the detail view based off the previous index.
 */
typedef NS_ENUM(NSInteger, LMDetailViewDisplayMode) {
	LMDetailViewDisplayModeNone = 0,
	LMDetailViewDisplayModeCurrentIndex,
	LMDetailViewDisplayModePreviousIndex
};

/**
 The index of the current item which is displaying its detail view for its contents. If none set, a value of LMNoDetailViewSelected will be assigned.
 */
@property NSInteger indexOfItemDisplayingDetailView;

/**
 The index (row) in the layout which is displaying the detail view. Returns LMNoDetailViewSelected if no detail view is selected.
 */
@property (readonly) NSInteger indexOfDetailView;

/**
 The index of the previous item which was displaying its detail view for its contents. If none was ever set, a value of LMNoDetailViewSelected will be returned.
 */
@property NSInteger previousIndexOfItemDisplayingDetailView;

/**
 The previous index (row) in the layout which was displaying the detail view. Returns LMNoDetailViewSelected if no detail view was ever selected.
 */
@property (readonly) NSInteger previousIndexOfDetailView;

/**
 Whether or not the flow layout is displaying a detail view.
 */
@property (readonly) BOOL isDisplayingDetailView;

/**
 The amount of cells which are overflowing cells to fit the detail view.
 */
@property (readonly) NSInteger amountOfOverflowingCellsForDetailView;

/**
 The amount of items to display per row. Default is based on device and orientation.
 */
@property (readonly) NSInteger itemsPerRow;

/**
 The amount of items in the current detail view.
 */
@property NSInteger amountOfItemsInDetailView;

/**
 The music track collections associated with the currently displaying data.
 */
@property NSArray<LMMusicTrackCollection*> *musicTrackCollections;

/**
 The frame of the current item displaying the detail view.
 */
@property CGRect frameOfItemDisplayingDetailView;

/**
 The music type which is currently being displayed in the flow layout/collection view.
 */
@property LMMusicType musicType;

/**
 The detail view which is currently being displayed by the flow layout. Should be used for calculating all size related things to it.
 */
@property LMEmbeddedDetailView *detailView;

/**
 The size of a normal item.
 */
@property CGSize normalItemSize;

/**
 The compact view which is displaying this flow layout.
 */
@property id compactView;

@end
