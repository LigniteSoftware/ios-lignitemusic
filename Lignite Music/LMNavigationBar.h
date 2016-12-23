//
//  LMNavigationBar.h
//  Lignite Music
//
//  Created by Edwin Finch on 12/22/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMView.h"

@interface LMNavigationBar : LMView

/**
 The bottom tabs of the navigation bar which control.
 */
typedef enum {
	LMNavigationTabBrowse = 0, //The browse tab for letter tabs and search.
	LMNavigationTabMiniplayer, //The mini player.
	LMNavigationTabView //The current view.
} LMNavigationTab;

@end
