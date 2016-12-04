//
//  LMSearchBar.h
//  Lignite Music
//
//  Created by Edwin Finch on 12/4/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMView.h"

@protocol LMSearchBarDelegate <NSObject>

/**
 The search term for the search bar changed.

 @param searchTerm The new search term.
 */
- (void)searchTermChangedTo:(NSString*)searchTerm;

/**
 The search dialog's opened status changed.

 @param opened Whether or not the dialog is open.
 @param keyboardHeight The height of the keyboard taking up room on screen.
 */
- (void)searchDialogOpened:(BOOL)opened withKeyboardHeight:(CGFloat)keyboardHeight;

@end

@interface LMSearchBar : LMView

/**
 The delegate for this search bar.
 */
@property id<LMSearchBarDelegate> delegate;

@end
