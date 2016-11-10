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
- (BOOL)buttonTappedWithIndex:(uint8_t)index forBigListEntry:(LMBigListEntry*)bigListEntry;
- (uint8_t)amountOfButtonsForBigListEntry:(LMBigListEntry*)bigListEntry;

/**
 See LMBigListEntryDelegate for more info on these delegate functions.
 */
- (id)contentSubviewForBigListEntry:(LMBigListEntry*)bigListEntry;
- (float)contentSubviewHeightFactorialForBigListEntry:(LMBigListEntry*)bigListEntry;

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

@end
