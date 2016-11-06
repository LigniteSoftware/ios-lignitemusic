//
//  LMNewTableView.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/6/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LMNewTableView;

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
- (id)subviewAtIndex:(NSUInteger)index forTableView:(LMNewTableView*)tableView;

/**
 Gets the height at a certain index for the table view.

 @param index The index of the height required.
 @param tableView The table view which is requesting the height.
 @return The height.
 */
- (float)heightAtIndex:(NSUInteger)index forTableView:(LMNewTableView*)tableView;

/**
 Gets the spacing at a certain index for the table view.

 @param index The index of the spacing requested.
 @param tableView The table view which is requesting the spacing.
 @return The spacing.
 */
- (float)spacingAtIndex:(NSUInteger)index forTableView:(LMNewTableView*)tableView;

/**
 Tells the delegate the amount of objects which are required for the table view. This will only be called upon when the amount of objects changes. The delegate should reload associated data and be prepared to pass new subviews in through subviewAtIndex:.

 @param amountOfObjects The new amount of objects that are required for this table view.
 @param tableView The table view which is telling the delegate the amount of objects required.
 */
- (void)amountOfObjectsRequiredChangedTo:(NSInteger)amountOfObjects forTableView:(LMNewTableView*)tableView;

@end

@interface LMNewTableView : UITableView

/**
 The average height of a cell. This will be used to calculate the amount of objects which are required for the table view. Must be set before any generation occurs.
 */
@property float averageCellHeight;

/**
 The total amount of objects which this table view will be required to display. This will be used for the count of the amount of cells being displayed and other data. Must be set before any generation occurs.
 */
@property NSUInteger totalAmountOfObjects;

/**
 Whether or not the table view should use light gray dividers in between all of the entries in the table view. Default is NO.
 */
@property BOOL shouldUseDividers;

/**
 The subview data source for this table view.
 */
@property id<LMTableViewSubviewDataSource> subviewDataSource;

@end
