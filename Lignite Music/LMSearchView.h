//
//  LMSearchView.h
//  Lignite Music
//
//  Created by Edwin Finch on 12/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMView.h"
#import "LMSearchBar.h"

@interface LMSearchView : LMView

/**
 The search term from the search bar changed.

 @param searchTerm The new search term.
 */
- (void)searchTermChangedTo:(NSString*)searchTerm;

@end
