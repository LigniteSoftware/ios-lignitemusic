//
//  LMListEntry.h
//  Lignite Music
//
//  Created by Edwin Finch on 9/29/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMOperationQueue.h"

@class LMListEntry;

@protocol LMListEntryDelegate <NSObject>

- (void)tappedListEntry:(LMListEntry*)entry;
- (UIColor*)tapColourForListEntry:(LMListEntry*)entry;
- (NSString*)titleForListEntry:(LMListEntry*)entry;
- (NSString*)subtitleForListEntry:(LMListEntry*)entry;
- (UIImage*)iconForListEntry:(LMListEntry*)entry;

@end

@interface LMListEntry : UIView

- (void)reloadContents;

- (void)changeHighlightStatus:(BOOL)highlighted animated:(BOOL)animated;

- (void)setup;

- (id)initWithDelegate:(id)delegate;

/**
 Don't fuck with this unless you know what you're doing boss
 */
@property UIView *contentView;

/**
 The multiplier of how much to inset the icon within its background view. For example, 0.5 would inset the icon half way into the background view, centered. Default after setup: 0.8
 */
@property float iconInsetMultiplier;

/**
 The multiplier which affects how much padding width-wise is allocated to the container of the icon. 1.0 is full width, meaning width equal to height, 0.0 is no width. Default after setup: 1.0
 */
@property float iconPaddingMultiplier;

/**
 The multiplier of the content view. Default after setup: 0.95
 */
@property float contentViewHeightMultiplier;

/**
 The index of this LMListEntry in the collection its associated with.
 */
@property NSInteger collectionIndex;

/**
 The index path in case the list entry is being used on a sectioned table view.
 */
@property NSIndexPath *indexPath;

/**
 Optional. Associated data with this LMListEntry.
 */
@property id associatedData;

/**
 Whether or not the list entry should invert its associated icon when it is highlighted. Default: NO
 */
@property BOOL invertIconOnHighlight;

/**
 The operation queue for this entry.
 */
@property LMOperationQueue *queue;

/**
 Set to YES if you know you will give the entry an icon. Otherwise, it will setup an imageview which will be very lonely.
 */
@property BOOL iPromiseIWillHaveAnIconForYouSoon;

/**
 The delegate for the list entry.
 */
@property id<LMListEntryDelegate> delegate;

@end
