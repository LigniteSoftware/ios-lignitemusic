//
//  TestingViewController.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/1/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LMTableView;

@protocol LMTableViewSubviewDelegate <NSObject>

/**
 Is called when a subview has been prepared internally by the LMAdaptivetableView. Usually this delegate function is used to handle any other rendering or constraint management which would need to occur for the subview.
 
 @param index     The index of that subview relative to the table view's total count of subviews available.
 
 @return The prepared subview.
 */
- (id)prepareSubviewAtIndex:(NSUInteger)index;


/**
 Gets the sizing factorial of an item in the table view relative to the window. The table view will handle the rest of the calculations.
 
 @param tableView The table view which requires the factorial.
 
 @return The factorial.
 */
- (float)sizingFactorialRelativeToWindowForTableView:(LMTableView*)tableView height:(BOOL)height;


/**
 Gets the amount of spacing the table view should add to the top of of the subviews.
 
 @param tableView The table view which wants the padding.
 
 @return The padding.
 */
- (float)topSpacingForTableView:(LMTableView*)tableView;


/**
 Whether or not the system should add a divider at the bottom of each of the the table view cells.
 
 @param tableView The table view in question.
 
 @return Whether or not a divider should be added.
 */
- (BOOL)dividerForTableView:(LMTableView*)tableView;

/**
 Whether or not the system should add a divider at the bottom of each of the the table view cells.
 
 @param tableView The table view in question.
 
 @return Whether or not a divider should be added.
 */
- (void)totalAmountOfSubviewsRequired:(NSUInteger)amount forTableView:(LMTableView*)tableView;

@end

@interface LMTableView : UITableView

@property NSInteger amountOfItemsTotal;
@property id subviewDelegate;
@property UIColor *dividerColour;

- (void)prepareForUse;

@end
