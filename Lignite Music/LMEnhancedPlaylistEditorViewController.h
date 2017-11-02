//
//  LMEnhancedPlaylistEditorViewController.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/31/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMPlaylistManager.h"

#define LMEnhancedPlaylistPersistentIDsKey @"persistentIDs"
#define LMEnhancedPlaylistMusicTypesKey @"musicTypes"

#define LMEnhancedPlaylistWantToHearKey @"wantToHear"
#define LMEnhancedPlaylistDontWantToHearKey @"dontWantToHear"

@class LMEnhancedPlaylistEditorViewController;

@protocol LMEnhancedPlaylistEditorDelegate<NSObject>

/**
 The user saved the enhanced playlist edits, contents should be reloaded if displaying playlist data.
 
 @param editorViewController The enhanced editor view controller responsible for editing.
 @param playlist The playlist edited.
 */
- (void)enhancedPlaylistEditorViewController:(LMEnhancedPlaylistEditorViewController*)enhancedEditorViewController didSaveWithPlaylist:(LMPlaylist*)playlist;

/**
 The playlist editor was cancelled.
 
 @param editorViewController The editor that was cancelled.
 */
- (void)enhancedPlaylistEditorViewControllerDidCancel:(LMEnhancedPlaylistEditorViewController*)enhancedEditorViewController;

@end

@interface LMEnhancedPlaylistEditorViewController : UIViewController

/**
 The delegate.
 */
@property id<LMEnhancedPlaylistEditorDelegate> delegate;

@end
