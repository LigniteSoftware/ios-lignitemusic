//
//  LMPlaylistView.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/28/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMBigListEntry.h"

@class LMBigListEntryTableView;

@protocol LMBigListEntryTableViewDelegate <NSObject>

/**
 See LMCollectionInfoViewDelegate for more info on these delegate functions.
 */
- (NSString*)titleForBigListEntry:(LMBigListEntry*)bigListEntry;
- (NSString*)leftTextForBigListEntry:(LMBigListEntry*)bigListEntry;
- (NSString*)rightTextForBigListEntry:(LMBigListEntry*)bigListEntry;
- (UIImage*)centerImageForBigListEntry:(LMBigListEntry*)bigListEntry;

/**
 See LMControlBarViewDelegate for more info on these delegate functions.
 */
- (UIImage*)imageWithIndex:(uint8_t)index forBigListEntry:(LMBigListEntry*)bigListEntry;
- (BOOL)buttonHighlightedWithIndex:(uint8_t)index wasJustTapped:(BOOL)wasJustTapped forBigListEntry:(LMBigListEntry*)bigListEntry;
- (uint8_t)amountOfButtonsForBigListEntry:(LMBigListEntry*)bigListEntry;

/**
 See LMBigListEntryDelegate for more info on these delegate functions.
 */
- (id)contentSubviewForBigListEntry:(LMBigListEntry*)bigListEntry;
- (float)contentSubviewFactorial:(BOOL)height forBigListEntry:(LMBigListEntry *)bigListEntry;

/**
 Asks the delegate to prepare a content subview for an associated big list entry.

 @param subview The subview which needs to be prepared.
 @param bigListEntry The big list entry which needs the content view prepared.
 */
- (void)prepareContentSubview:(id)subview forBigListEntry:(LMBigListEntry *)bigListEntry;

@optional

/**
 See LMBigListEntryDelegate for more info on this optional delegate function.
 */
- (void)contentViewTappedForBigListEntry:(LMBigListEntry *)bigListEntry;

@end

@interface LMBigListEntryTableView : UIView

/**
 The delegate provides some data for each the LMCollectionInfoView, LMControlBarView and LMBigListEntry.
 */
@property id<LMBigListEntryTableViewDelegate>delegate;

/**
 The total amount of objects for this table view.
 */
@property NSUInteger totalAmountOfObjects;

/**
 Setup the table view.
 */
- (void)setup;

/**
 Reload the control bars which are associated with the big list entries of this view.
 */
- (void)reloadControlBars;

/**
 Reload the core table view's data, which will simply redraw anything on screen.
 */
- (void)reloadData;

@end
