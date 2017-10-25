//
//  LMMusicPickerController.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/23/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMMusicPlayer.h"

@class LMMusicPickerController;

@protocol LMMusicPickerDelegate
@optional

/**
 The music picker finished picking music (the user tapped "Done") and the track collection provided is the latest and greatest available.

 @param musicPicker The music picker which has finished selection.
 @param trackCollection The track collection which is the final product of the picker.
 */
- (void)musicPicker:(LMMusicPickerController*)musicPicker didFinishPickingMusicWithTrackCollection:(LMMusicTrackCollection*)trackCollection;

/**
 The user cancelled picking music and the trackCollection that may exist should be ignored.

 @param musicPicker The music picker which the user cancelled for.
 */
- (void)musicPickerDidCancelPickingMusic:(LMMusicPickerController*)musicPicker;

@end

@interface LMMusicPickerController : UIViewController


/**
 Sets a track as selected. If NO, the track will be removed from the trackCollection.

 @param track The track to change selection for.
 @param selected Whether or not the track is selected.
 */
- (void)setTrack:(LMMusicTrack*)track asSelected:(BOOL)selected;


/**
 The delegate for music picking notifications.
 */
@property id<LMMusicPickerDelegate> delegate;

/**
 The collection of tracks currently chosen by the user. To prepopulate the picker with already selected tracks, set this before load.
 */
@property LMMusicTrackCollection *trackCollection;


@end
