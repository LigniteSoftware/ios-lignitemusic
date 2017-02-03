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
#import "LMOperationQueue.h"

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

 @param height Whether or not it wants the height factorial.
 @param bigListEntry The big list entry.
 @return The content factorial.
 */
- (float)contentSubviewFactorial:(BOOL)height forBigListEntry:(LMBigListEntry*)bigListEntry;

/**
 Is called when the size to the big list entry changes. This should only happen when the UIControlBarView changes its size in portrait.

 @param largeSize Whether or not the big list entry is now large.
 @param withHeight The new height of the big list entry.
 @param bigListEntry The big list entry.
 */
- (void)sizeChangedToLargeSize:(BOOL)largeSize withHeight:(float)newHeight forBigListEntry:(LMBigListEntry*)bigListEntry;

@optional

/**
 A content view was tapped on this big list entry.

 @param bigListEntry The big list entry which was tapped.
 */
- (void)contentViewTappedForBigListEntry:(LMBigListEntry*)bigListEntry;

/*
 * Quick Copy Paste
 *
 
 - (id)contentSubviewForBigListEntry:(LMBigListEntry*)bigListEntry;
 - (float)contentSubviewFactorial:(BOOL)height forBigListEntry:(LMBigListEntry*)bigListEntry;
 - (void)sizeChangedToLargeSize:(BOOL)largeSize withHeight:(float)newHeight forBigListEntry:(LMBigListEntry*)bigListEntry;
 
 - (void)contentViewTappedForBigListEntry:(LMBigListEntry*)bigListEntry;
 */

@end

@interface LMBigListEntry : UIView

@property id<LMBigListEntryDelegate> entryDelegate;
@property id<LMCollectionInfoViewDelegate> infoDelegate;
@property id<LMControlBarViewDelegate> controlBarDelegate;

@property BOOL isLargeSize;
@property NSUInteger collectionIndex;

@property LMOperationQueue *queue;

/**
 The info view for the big list entry.
 */
@property LMCollectionInfoView *collectionInfoView;

/**
 How much the width of the content view should take up in multiplier sense. 1.0 will touch both edges of the big list entry. Default is 0.8.
 */
@property float contentViewWidthMultiplier;

/**
 Gets the size of a big list entry with an associated delegate for whether or not it is open.

 @param opened Whether or not it is open.
 @param delegate The delegate associated.
 @return The size of the big list entry.
 */
+ (float)sizeForBigListEntryWhenOpened:(BOOL)opened forDelegate:(id<LMBigListEntryDelegate>)delegate;

/**
 Set the big list entry as large or not.

 @param large The BOOL to make it large.
 @param animated Whether or not to animate the change. NO if view is off-screen.
 */
- (void)setLarge:(BOOL)large animated:(BOOL)animated;

/**
 Reload the data of the big list entry.
 
 @param fullReload Whether or not the entry should fully reload itself. Full reload includes regrabbing info view contents and setting the content subview again. Setting to NO will only reload the control bar highlighters.
 */
- (void)reloadData:(BOOL)fullReload;

- (void)setup;

@end
