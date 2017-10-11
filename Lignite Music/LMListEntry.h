//
//  LMListEntry.h
//  Lignite Music
//
//  Created by Edwin Finch on 9/29/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MGSwipeTableCell/MGSwipeTableCell.h>
#import "LMOperationQueue.h"

@class LMListEntry;

@protocol LMListEntryDelegate <NSObject>

- (void)tappedListEntry:(LMListEntry*)entry;
- (UIColor*)tapColourForListEntry:(LMListEntry*)entry;
- (NSString*)titleForListEntry:(LMListEntry*)entry;
- (NSString*)subtitleForListEntry:(LMListEntry*)entry;
- (UIImage*)iconForListEntry:(LMListEntry*)entry;

@optional

/**
 Gets text for the list entry which goes where the icon goes. If the delegate responds to this selector, the icon will be overridden by this and this will be called on refresh.

 @param entry The entry to get the text for.
 @return The text.
 */
- (NSString*)textForListEntry:(LMListEntry*)entry;

@end

@interface LMListEntry : UIView

- (void)reloadContents;

- (void)changeHighlightStatus:(BOOL)highlighted animated:(BOOL)animated;

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
 Whether or not to align the icon to the far left of the view.
 */
@property BOOL alignIconToLeft;

/**
 Whether or not to base off the label instead of icon. If yes, the textForListEntry: will be called and the delegate must conform to it.
 */
@property BOOL isLabelBased;

/**
 Stretch the whole thing across all available width, from edge to edge. Feeling edgy.
 */
@property BOOL stretchAcrossWidth;

/**
 The delegate for the list entry.
 */
@property id<LMListEntryDelegate> delegate;

/**
 The buttons that go to the left of the list entry, which when swiped from left to right on, are revealed.
 
 Default is an empty array.
 */
@property NSArray<MGSwipeButton*>* leftButtons;

/**
 The buttons that go to the right of the list entry, which when swiped from right to left on, are revealed.
 
 Default is an empty array.
 */
@property NSArray<MGSwipeButton*>* rightButtons;

@end
