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

/*
 * Thank you past Edwin :)
 *
 
 - (void)tappedListEntry:(LMListEntry*)entry {
 NSLog(@"Tapped %@", entry);
 }
 
 - (UIColor*)tapColourForListEntry:(LMListEntry*)entry {
 return [UIColor redColor];
 }
 
 - (NSString*)titleForListEntry:(LMListEntry*)entry {
 return @"Tytle";
 }
 
 - (NSString*)subtitleForListEntry:(LMListEntry*)entry {
 return @"Subtitle";
 }
 
 - (UIImage*)iconForListEntry:(LMListEntry*)entry {
 return [LMAppIcon imageForIcon:LMIconBug];
 }

 */

@optional

/**
 Gets text for the list entry which goes where the icon goes. If the delegate responds to this selector, the icon will be overridden by this and this will be called on refresh.

 @param entry The entry to get the text for.
 @return The text.
 */
- (NSString*)textForListEntry:(LMListEntry*)entry;

/**
 Called upon to return a view which will add that subview provided to the right of the list entry. Any text will be automatically pinned to the leading edge of the view to ensure proper wrapping. Views returned by this function should realize the list entry only provides 1/10th of its space.

 @param entry The entry for the view.
 @return The view that the delegate wants to add to the right of the entry.
 */
- (UIView*)rightViewForListEntry:(LMListEntry*)entry;

/**
 Called upon to return an array of buttons to add to a certain side of the list entry.

 @param listEntry The list entry to apply the buttons for.
 @param rightSide Whether or not the list entry wants the right side buttons. NO for left side.
 @return The array of buttons.
 */
- (NSArray<MGSwipeButton*>*)swipeButtonsForListEntry:(LMListEntry*)listEntry rightSide:(BOOL)rightSide;

/**
 Called upon to return an array of colours to apply to the swipe buttons of a certain side of the list entry.

 @param listEntry The list entry to apply the swipe button colours for.
 @param rightSide Whether or not the list entry wants the right side swipe button colours. NO for left side.
 @return The array of swipe button colours.
 */
- (UIColor*)swipeButtonColourForListEntry:(LMListEntry*)listEntry rightSide:(BOOL)rightSide;

@end

@interface LMListEntry : UIView

/**
 Reloads the list entry's contents.
 */
- (void)reloadContents;

/**
 Changes the highlight status of the list entry.

 @param highlighted Whether or not to highlight this entry.
 @param animated Whether or not to animate the change in highlight.
 */
- (void)setAsHighlighted:(BOOL)highlighted animated:(BOOL)animated;

/**
 Resets the swipe buttons back to being hidden, optionally animated.

 @param animated Whether or not to animate the buttons.
 */
- (void)resetSwipeButtons:(BOOL)animated;

/**
 Initializes a list entry with a delegate.

 @param delegate The delegate to set to the list entry.
 @return The initialized list entry.
 */
- (id)initWithDelegate:(id)delegate;

/**
 Don't fuck with this unless you know what you're doing boss
 */
@property UIView *contentView;

/**
 Optional. The top constraint for the list entry, used if modifications are necessary during runtime.
 */
@property NSLayoutConstraint *topConstraint;

/**
 Optional. The bottom constraint for the list entry, used if modifications are necessary during runtime.
 */
@property NSLayoutConstraint *bottomConstraint;

/**
 Keep the text colours the same on highlight. Defaults to NO.
 */
@property BOOL keepTextColoursTheSame;

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
 The title label's height multiplier, default is (1.0/3.0).
 */
@property float titleLabelHeightMultipler;

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
@property NSArray<MGSwipeButton*>* leftButtons DEPRECATED_ATTRIBUTE;

/**
 The buttons that go to the right of the list entry, which when swiped from right to left on, are revealed.
 
 Default is an empty array.
 */
@property NSArray<MGSwipeButton*>* rightButtons DEPRECATED_ATTRIBUTE;

/**
 The expansion colour for the left button.
 */
@property UIColor* leftButtonExpansionColour DEPRECATED_ATTRIBUTE;

/**
 The expansion colour for the right button.
 */
@property UIColor* rightButtonExpansionColour DEPRECATED_ATTRIBUTE;

/**
 Whether or not to round the corners on the icon. Default is YES.
 */
@property BOOL roundedCorners;

/**
 Used for previous tracks queue entry swipe animation focusing.
 */
@property CGFloat previousAlpha;

@end
