//
//  LMSectionTableView.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/20/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MGSwipeTableCell/MGSwipeTableCell.h>

@class LMSectionTableView;

@protocol LMSectionTableViewDelegate <NSObject>
@required

/**
 Gets an icon for a section header.

 @param section The section requiring.
 @param sectionTableView The associated table view.
 @return The icon.
 */
- (UIImage*)iconAtSection:(NSInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView;

/**
 Gets a title for a section header.

 @param section The section requiring.
 @param sectionTableView The associated table view.
 @return The title.
 */
- (NSString*)titleAtSection:(NSInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView;

/**
 Gets the number of rows of items per a section.

 @param section The section requiring.
 @param sectionTableView The associated table view.
 @return The number of rows for that section.
 */
- (NSUInteger)numberOfRowsForSection:(NSInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView;

/**
 Gets a title for a certain index path.

 @param indexPath The index path.
 @param sectionTableView The associated table view.
 @return The title for that index path.
 */
- (NSString*)titleForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView;

/**
 Gets a subtitle for a certain index path.

 @param indexPath The index path.
 @param sectionTableView The associated table view.
 @return The subtitle.
 */
- (NSString*)subtitleForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView;

/**
 Gets an icon for a certain index path.

 @param indexPath The index path.
 @param sectionTableView The associated table view.
 @return The icon.
 */
- (UIImage*)iconForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView;

/**
 An index path was tapped.

 @param indexPath The index path which was tapped.
 @param sectionTableView The table view which the tap was performed on.
 */
- (void)tappedIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView;

/**
 * Quick copy and paste
 *
 
- (UIImage*)iconAtSection:(NSInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView;
- (NSString*)titleAtSection:(NSInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView;
- (NSUInteger)numberOfRowsForSection:(NSInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView;
- (NSString*)titleForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView;
- (NSString*)subtitleForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView;
- (UIImage*)iconForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView;
- (void)tappedIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView;
 
- (UIView*)rightViewForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView;
 
 */

@optional

/**
 Gets the accessory view for the index path. Can be nil.

 @param indexPath The index path that wants the accessory view.
 @param sectionTableView The table view associated.
 @return The view.
 */
- (id)accessoryViewForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView;

/**
 Gets the right side view for the list entry at a certain index.
 
 @param indexPath The index path to return the view for.
 @param sectionTableView The section table which has the entry that wants the right view.
 @return The view for the entry.
 */
- (UIView*)rightViewForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView;

/**
 The close button was tapped.

 @param sectionTableView The section table view which had its close button tapped.
 */
- (void)tappedCloseButtonForSectionTableView:(LMSectionTableView*)sectionTableView;

/**
 Gets the swipe buttons for an index path. If swipe buttons are returned, the user will be able to swipe in the associated direction to perform an action on an MGSwipeButton.

 @param indexPath The index path of the cell that wants the swipe buttons.
 @param rightSide Whether or not the buttons that are being returned will be on the right side.
 @return The swipe buttons, nil if no buttons should be used.
 */
- (NSArray<MGSwipeButton*>*)swipeButtonsForIndexPath:(NSIndexPath*)indexPath rightSide:(BOOL)rightSide;

/**
 Same as for getting the swipe buttons, this returns the colours for the buttons when their action is performed.

 @param indexPath The index path of the cell that wants the swipe colour.
 @param rightSide Whether or not the colour that are being returned will be on the right side.
 @return The swipe colour.
 */
- (UIColor*)swipeButtonColourForIndexPath:(NSIndexPath*)indexPath rightSide:(BOOL)rightSide;

/**
 Gets the accessibility label for an index path.

 @param indexPath The index path of the associated label.
 @return The label, localized to the user's language.
 */
- (NSString*)accessibilityLabelForIndexPath:(NSIndexPath*)indexPath;

/**
 Gets the hint label for an index path.
 
 @param indexPath The index path of the associated hint.
 @return The hint, localized to the user's language.
 */
- (NSString*)accessibilityHintForIndexPath:(NSIndexPath*)indexPath;

@end

@interface LMSectionTableView : UITableView

/**
 Title for the section table view.
 */
@property NSString *title;

/**
 The delegate for the data that will go inside the table view.
 */
@property id<LMSectionTableViewDelegate> contentsDelegate;

/**
 The total number of sections for this sectioned table view.
 */
@property NSUInteger totalNumberOfSections;

/**
 Setup the section table view.
 */
- (void)setup;

/**
 Register the cell identifiers.
 */
- (void)registerCellIdentifiers;

@end
