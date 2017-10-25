//
//  LMPlaylistEditorViewController.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/22/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMPlaylistManager.h"

@class LMPlaylistEditorViewController;

@protocol LMPlaylistEditorDelegate<NSObject>
@optional

/**
 The user saved the playlist edits, contents should be reloaded if displaying playlist data.

 @param editorViewController The editor view controller responsible for editing.
 @param playlist The playlist edited.
 */
- (void)playlistEditorViewController:(LMPlaylistEditorViewController*)editorViewController didSaveWithPlaylist:(LMPlaylist*)playlist;

/**
 The playlist editor was cancelled.

 @param editorViewController The editor that was cancelled.
 */
- (void)playlistEditorViewControllerDidCancel:(LMPlaylistEditorViewController*)editorViewController;

@end

@interface LMPlaylistEditorViewController : UIViewController

/**
 The delegate.
 */
@property id<LMPlaylistEditorDelegate> delegate;

/**
 The playlist that is being edited/created by the playlist editor. Set this before load to automatically populate all fields with a playlist for editing.
 */
@property LMPlaylist *playlist;

@end
