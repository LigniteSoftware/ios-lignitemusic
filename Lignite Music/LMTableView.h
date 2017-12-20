//
//  LMTableView.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/6/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DDTableView.h"

@class LMTableView;

/**
 The subview data source exchanges information related to the table view's contents. It provides subviews, dimensions, and is told when anything updates which will require the data source's attention.
 */
@protocol LMTableViewSubviewDataSource <NSObject>

/**
 Gets the subview at a certain index for the table view. The subview will be pinned to all edges of the cell's content view and its compression resistance will be set to required.

 @param index The index of the subview required.
 @param tableView The table view which is requesting the subview.
 @return The subview.
 */
- (id)subviewAtIndex:(NSUInteger)index forTableView:(LMTableView*)tableView;

/**
 Gets the height at a certain index for the table view.

 @param index The index of the height required.
 @param tableView The table view which is requesting the height.
 @return The height.
 */
- (CGFloat)heightAtIndex:(NSUInteger)index forTableView:(LMTableView*)tableView;

/**
 Gets the spacing at a certain index for the table view.

 @param index The index of the spacing requested.
 @param tableView The table view which is requesting the spacing.
 @return The spacing.
 */
- (CGFloat)spacingAtIndex:(NSUInteger)index forTableView:(LMTableView*)tableView;

/**
 Tells the delegate the amount of objects which are required for the table view. This will only be called upon when the amount of objects changes. The delegate should reload associated data and be prepared to pass new subviews in through subviewAtIndex:.

 @param amountOfObjects The new amount of objects that are required for this table view.
 @param tableView The table view which is telling the delegate the amount of objects required.
 */
- (void)amountOfObjectsRequiredChangedTo:(NSUInteger)amountOfObjects forTableView:(LMTableView*)tableView;

/*
 * Quick copy and paste
 *
- (id)subviewAtIndex:(NSUInteger)index forTableView:(LMTableView*)tableView;
- (CGFloat)heightAtIndex:(NSUInteger)index forTableView:(LMTableView*)tableView;
- (CGFloat)spacingAtIndex:(NSUInteger)index forTableView:(LMTableView*)tableView;
- (void)amountOfObjectsRequiredChangedTo:(NSUInteger)amountOfObjects forTableView:(LMTableView*)tableView;
 */

@end

@interface LMTableView : DDTableView

/**
 The amount of spacing you'd like between the bottom of the table view and the last entry in it. Default is 0.
 */
@property NSUInteger bottomSpacing;

/**
 The title of this LMTableView. Is used for the cell identifiers and to log information about the LMTableView.
 */
@property NSString *title;

/**
 The average height of a cell. This will be used to calculate the amount of objects which are required for the table view. Must be set before any generation occurs.
 */
@property CGFloat averageCellHeight;

/**
 The total amount of objects which this table view will be required to display. This will be used for the count of the amount of cells being displayed and other data. Must be set before any generation occurs.
 */
@property NSUInteger totalAmountOfObjects;

/**
 Whether or not the table view should use light gray dividers in between all of the entries in the table view. Default is NO.
 */
@property BOOL shouldUseDividers;

/**
 Whether or not to stretch the dividers across the whole width. Default is NO, which results in a 90% stretch.
 */
@property BOOL fullDividers;

/**
 Whether or not the first entry in the table view should have a clear background colour. YES for views such as the detail view. Default is NO.
 */
@property BOOL firstEntryClear;

/**
 The colour of the dividers. Default is [UIColor blackColor].
 */
@property UIColor *dividerColour;

/**
 The divider sections to ignore. Should be an array of NSNumbers. Each number which is in here will not show a divider for that associated section when shouldUseDividers is YES.
 */
@property NSArray *dividerSectionsToIgnore;

/**
 The secondary delegate which will get some table view delegate information such as changes in scroll dragging.
 */
@property id<UITableViewDelegate> secondaryDelegate;

/**
 The subview data source for this table view.
 */
@property id<LMTableViewSubviewDataSource> subviewDataSource;

/**
 Add white space to the bottom of the content on the scroll view to prevent shit from going down.
 */
@property BOOL addBottomWhiteSpace;

/**
 The background colour to use for when an entry isn't highlighted. Default is whiteColour.
 */
@property UIColor *notHighlightedBackgroundColour;

/**
 Reloads the subview data. Recalculates the amount of objects required, sets up the basic layout of the table view (ie. background colour) and tells delegate of new calculations.
 */
- (void)reloadSubviewData;

/**
 Reloads the subview sizes (cell sizes) based on delegate provided data.
 */
- (void)reloadSubviewSizes;

/**
 Briefly focus a cell at a certain index.

 @param index The index to focus.
 */
- (void)focusCellAtIndex:(NSUInteger)index;

@end
