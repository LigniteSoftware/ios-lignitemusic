//
//  DDTableView.h
//  ReorderTest
//
//  Created by Edwin Finch on 10/13/17.
//  Copyright © 2017 Techno-Magic. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DDTableView;


@protocol DDTableViewDelegate <NSObject>

/**
 Provides the delegate a chance to modify the cell visually before dragging occurs. Defaults to using the cell as-is if not implemented.

 @param tableView The table view which the associated modifying cell is from.
 @param cell The cell to modify.
 @param indexPath The index path that the cell is at.
 @return The modified cell.
 */
- (UITableViewCell*)tableView:(UITableView*)tableView draggingCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath;

/**
 Called within an animation block when the dragging view is about to show.

 @param tableView The table view which the associated dragging view is from.
 @param draggingView The dragging view which is about to show.
 @param indexPath The index path of the cell associated with this dragging view.
 */
- (void)tableView:(UITableView*)tableView showDraggingView:(UIView*)draggingView atIndexPath:(NSIndexPath*)indexPath;

/**
 @param tableView The table view which the associated modifying cell is from.

 @param tableView The table view which the associated dragging view is from.
 @param draggingView The dragging view which is about to show.
 @param indexPath The index path of the cell associated with this dragging view.
 */
- (void)tableView:(UITableView*)tableView hideDraggingView:(UIView*)draggingView atIndexPath:(NSIndexPath*)indexPath;

/**
 Called when the dragging gesture's vertical location changes.

 @param tableView The table view associated with the gesture view.
 @param gesture The gesture whose vertical location changed.
 */
- (void)tableView:(UITableView*)tableView draggingGestureChanged:(UILongPressGestureRecognizer*)gesture;

@end


@interface DDTableView : UITableView

/**
 The delegate for long press reordering events.
 */
@property id<DDTableViewDelegate> longPressReorderDelegate;

/**
 Whether or not long-press to reorder is enabled. Default is NO.
 */
@property BOOL longPressReorderEnabled;

@end
