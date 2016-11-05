//
//  LMBigListEntry.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/1/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMCollectionInfoView.h"
#import "LMControlBarView.h"

@class LMBigListEntry;

@protocol LMBigListEntryDelegate <NSObject>

/**
 Get the content subview for the big list entry, which is the main "image type" view which goes above the info view. Automatically has shadow applied behind it.

 @param bigListEntry The big list entry which requires the content view.
 @return The content view.
 */
- (id)contentSubviewForBigListEntry:(LMBigListEntry*)bigListEntry;

/**
 Get the content subview's height factorial (percentage) for the big list entry.

 @param bigListEntry The big list entry.
 @return The content factorial.
 */
- (float)contentSubviewHeightFactorialForBigListEntry:(LMBigListEntry*)bigListEntry;

/**
 Is called when the size to the big list entry changes. This should only happen when the UIControlBarView changes its size in portrait.

 @param largeSize Whether or not the big list entry is now large.
 @param withHeight The new height of the big list entry.
 @param bigListEntry The big list entry.
 */
- (void)sizeChangedToLargeSize:(BOOL)largeSize withHeight:(float)newHeight forBigListEntry:(LMBigListEntry*)bigListEntry;

@end

@interface LMBigListEntry : UIView

@property id<LMBigListEntryDelegate> entryDelegate;
@property id<LMCollectionInfoViewDelegate> infoDelegate;

@property BOOL isLargeSize;
@property NSUInteger collectionIndex;

/**
 Gets the small/average size of the big list entry with a provided delegate. Warning: will pass nil to contentSubviewHeightFactorialForBigListEntry:.

 @param delegate The delegate associated.
 @return The height in px.
 */
+ (float)smallSizeForBigListEntryWithDelegate:(id<LMBigListEntryDelegate>)delegate;

/**
 Set the big list entry as large or not.

 @param large The BOOL to make it large.
 */
- (void)setLarge:(BOOL)large;

@end
