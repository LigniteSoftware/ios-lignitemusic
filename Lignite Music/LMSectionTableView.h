//
//  LMSectionTableView.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/20/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LMSectionTableView;

@protocol LMSectionTableViewDelegate <NSObject>

/**
 Gets an icon for a section header.

 @param section The section requiring.
 @param sectionTableView The associated table view.
 @return The icon.
 */
- (UIImage*)iconAtSection:(NSUInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView;

/**
 Gets a title for a section header.

 @param section The section requiring.
 @param sectionTableView The associated table view.
 @return The title.
 */
- (NSString*)titleAtSection:(NSUInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView;

/**
 Gets the number of rows of items per a section.

 @param section The section requiring.
 @param sectionTableView The associated table view.
 @return The number of rows for that section.
 */
- (NSUInteger)numberOfRowsForSection:(NSUInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView;

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
 * Quick copy and paste
 *
 
- (UIImage*)iconAtSection:(NSUInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView;
- (NSString*)titleAtSection:(NSUInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView;
- (NSUInteger)numberOfRowsForSection:(NSUInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView;
- (NSString*)titleForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView;
- (NSString*)subtitleForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView;
- (UIImage*)iconForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView;
 
 */

@end

@interface LMSectionTableView : UIView

/**
 The delegate for the data that will go inside the table view.
 */
@property id<LMSectionTableViewDelegate> delegate;

/**
 The number of sections for this sectioned table view.
 */
@property NSUInteger numberOfSections;

/**
 Setup the section table view.
 */
- (void)setup;

@end
