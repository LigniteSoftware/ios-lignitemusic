//
//  InterfaceController.h
//  Abbey For Apple Watch Extension
//
//  Created by Edwin Finch on 11/7/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface LMWMainInterfaceController : WKInterfaceController

/**
 The title label.
 */
@property IBOutlet WKInterfaceLabel *titleLabel;

/**
 The subtitle label.
 */
@property IBOutlet WKInterfaceLabel *subtitleLabel;

/**
 The album art image.
 */
@property IBOutlet WKInterfaceImage *albumArtImage;

/**
 The image for the favourites heart.
 */
@property IBOutlet WKInterfaceImage *favouriteImage;

/**
 The image for the shuffle button.
 */
@property IBOutlet WKInterfaceImage *shuffleImage;

/**
 The image for the repeat button.
 */
@property IBOutlet WKInterfaceImage *repeatImage;

/**
 The image for the play/pause button.
 */
@property IBOutlet WKInterfaceImage *playPauseImage;

/**
 The image for the next track button.
 */
@property IBOutlet WKInterfaceImage *nextTrackImage;

/**
 The image for the previous track button.
 */
@property IBOutlet WKInterfaceImage *previousTrackImage;

/**
 The image for the volume down button.
 */
@property IBOutlet WKInterfaceImage *volumeDownImage;

/**
 The image for the volume up button.
 */
@property IBOutlet WKInterfaceImage *volumeUpImage;

/**
 The group of the volume bar which is coloured red and displays the phone's volume level. Linked through an IBOutlet to provide to our LMWProgressSliderInfo instance, so it can handle the sizing to display progress.
 */
@property IBOutlet WKInterfaceGroup *volumeBarGroup;

/**
 The group for the shuffle button which is highlighted when the shuffle mode is active.
 */
@property IBOutlet WKInterfaceGroup *shuffleButtonGroup;

/**
 The group for the repeat button, which is highlighted when the repeat mode is not completely off.
 */
@property IBOutlet WKInterfaceGroup *repeatButtonGroup;

/**
 The group of the actual progress bar which is coloured red and contains the white grabber. Linked through an IBOutlet to provide to our LMWProgressSliderInfo instance, so it can handle the sizing to display progress.
 */
@property IBOutlet WKInterfaceGroup *progressBarGroup;

/**
 The container for the progress bar, which is also passed to the instance of LMWProgressSliderInfo to allow for resizing of the height of the progress bar. Shaded gray in the interface builder.
 */
@property IBOutlet WKInterfaceGroup *progressBarContainer;

/**
 The main controls container (which is auto-hidden if the setting is included).
 */
@property IBOutlet WKInterfaceGroup *mainControlsContainer;

/**
 The group for the up next label.
 */
@property IBOutlet WKInterfaceGroup *upNextGroup;

/**
 The up next label.
 */
@property IBOutlet WKInterfaceLabel *upNextLabel;

/**
 The now playing queue table.
 */
@property IBOutlet WKInterfaceTable *queueTable;

/**
 The group for the nothing playing display.
 */
@property IBOutlet WKInterfaceGroup *nothingPlayingGroup;

/**
 The label for when nothing's playing.
 */
@property IBOutlet WKInterfaceLabel *nothingPlayingLabel;

/**
 The group for displaying errors to the user.
 */
@property IBOutlet WKInterfaceGroup *errorGroup;

/**
 The label for displaying errors to the user.
 */
@property IBOutlet WKInterfaceLabel *errorLabel;

/**
 The group for the now playing screen.
 */
@property IBOutlet WKInterfaceGroup *nowPlayingGroup;

/**
 The group for extra music controls.
 */
@property IBOutlet WKInterfaceGroup *extraControlsGroup;

/**
 The group for the browse button's background which contains its colour.
 */
@property IBOutlet WKInterfaceGroup *browseButtonBackgroundGroup;

/**
 The label for the browse library button.
 */
@property IBOutlet WKInterfaceLabel *browseLibraryLabel;

/**
 The group for the browse button's background which contains its colour.
 */
@property IBOutlet WKInterfaceGroup *nothingPlayingBrowseButtonBackgroundGroup;

/**
 The label for the nothing playing browse library button.
 */
@property IBOutlet WKInterfaceLabel *nothingPlayingBrowseLibraryLabel;

/**
 The pan gesture changed for the progress bar. Should be passed right away to the LMWProgressSliderInfo instance.

 @param panGestureRecognizer The pan gesture object.
 */
- (IBAction)progressPanGesture:(WKPanGestureRecognizer*)panGestureRecognizer;

/**
 The favourites button's "tap handler".
 
 @param sender The sender of the action.
 */
- (IBAction)favouriteButtonSelector:(id)sender;

/**
 The shuffle button's "tap handler".

 @param sender The sender of the action.
 */
- (IBAction)shuffleButtonSelector:(id)sender;

/**
 The repeat button's "tap handler".
 
 @param sender The sender of the action.
 */
- (IBAction)repeatButtonSelector:(id)sender;

/**
 The browse library button's "tap handler".
 
 @param sender The sender of the action.
 */
- (IBAction)browseLibraryButtonSelector:(id)sender;

/**
 The album covers's "tap handler", for revealing the main controls if auto-hide is on.
 
 @param sender The sender of the action.
 */
- (IBAction)mainControlsAlbumCoverSelector:(id)sender;

- (IBAction)nextTrackButtonSelector:(id)sender;
- (IBAction)previousTrackButtonSelector:(id)sender;
- (IBAction)playPauseButtonSelector:(id)sender;
- (IBAction)volumeDownButtonSelector:(id)sender;
- (IBAction)volumeUpButtonSelector:(id)sender;

/**
 Writes a string to the title label.

 @param debugMessage The debug message to write.
 */
- (void)debug:(NSString*)debugMessage;

@end
